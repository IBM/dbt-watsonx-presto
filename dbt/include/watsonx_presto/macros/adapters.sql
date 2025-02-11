
-- - get_catalog
-- - list_relations_without_caching
-- - get_columns_in_relation

{% macro watsonx_presto__get_columns_in_relation(relation) -%}
  {% call statement('get_columns_in_relation', fetch_result=True) %}
      select
          column_name,
          case when regexp_like(data_type, 'varchar\(\d+\)') then 'varchar'
               else data_type
          end as data_type,
          case when regexp_like(data_type, 'varchar\(\d+\)') then
                  from_base(regexp_extract(data_type, 'varchar\((\d+)\)', 1), 10)
               else NULL
          end as character_maximum_length,
          NULL as numeric_precision,
          NULL as numeric_scale

      from
      {{ relation.information_schema('columns') | lower()}}

      where
        table_name = '{{ relation.name }}'
        {% if relation.schema %}
        and table_schema = '{{ relation.schema }}'
        {% endif %}
      order by ordinal_position

  {% endcall %}

  {% set table = load_result('get_columns_in_relation').table %}
  {{ return(sql_convert_columns_in_relation(table)) }}
{% endmacro %}


{% macro watsonx_presto__list_relations_without_caching(relation) %}
{% set information_schema = relation.information_schema() | lower %}
  {% call statement('list_relations_without_caching', fetch_result=True) -%}
    select
      table_catalog as database,
      table_name as name,
      table_schema as schema,
      case when table_type = 'BASE TABLE' then 'table'
           when table_type = 'VIEW' then 'view'
           else table_type
      end as table_type
    from {{ information_schema }}.tables
    where table_schema = '{{ relation.schema }}'
  {% endcall %}
  {{ return(load_result('list_relations_without_caching').table) }}
{% endmacro %}


{% macro watsonx_presto__reset_csv_table(model, full_refresh, old_relation, agate_table) %}
    {{ adapter.drop_relation(old_relation) }}
    {{ return(create_csv_table(model, agate_table)) }}
{% endmacro %}


{% macro watsonx_presto__create_csv_table(model, agate_table) %}
  {%- set column_override = model['config'].get('column_types', {}) -%}
  {%- set quote_seed_column = model['config'].get('quote_columns', None) -%}
  {%- set _properties = config.get('properties') -%}

  {% set sql %}
    create table {{ this.render() }} (
        {%- for col_name in agate_table.column_names -%}
            {%- set inferred_type = adapter.convert_type(agate_table, loop.index0) -%}
            {%- set type = column_override.get(col_name, inferred_type) -%}
            {%- set column_name = (col_name | string) -%}
            {{ adapter.quote_seed_column(column_name, quote_seed_column) }} {{ type }} {%- if not loop.last -%}, {%- endif -%}
        {%- endfor -%}
    ) {{ properties(_properties) }}
  {% endset %}

  {% call statement('_') -%}
    {{ sql }}
  {%- endcall %}

  {{ return(sql) }}
{% endmacro %}


{% macro generate_bindings(row_values, column_types) %}
  {% set formatted_values = [] %}

  {%- for value in row_values -%}
    {%- if value is not none -%}
      {% set regex_module = modules.re %}
      {%- set matched_type = regex_module.match("(\w+)(\(.*\))?", column_types[loop.index0]) -%}
      {%- set type_category = matched_type.group(1).lower() -%}

      {% if 'interval' in type_category %}
        {%- do formatted_values.append((none, type_category.upper() ~ " " ~ value)) -%}
      {% elif 'hyperloglog' in type_category or 'p4hyperloglog' in type_category or 'khyperloglog' in type_category %}
        {%- do formatted_values.append((none, "CAST(" ~ value ~ " AS " ~ type_category.upper() ~ ")")) -%}
      {% elif 'array' in type_category or 'map' in type_category or 'row' in type_category %}
        {%- do formatted_values.append((none, type_category.upper() ~ value.strip("'\""))) -%}
      {% elif 'varchar' in type_category or 'char' in type_category %}
        {%- do formatted_values.append((get_binding_char(), value|string())) -%}
      {% elif value is string %}
        {%- do formatted_values.append((none, type_category.upper() ~ " '" ~ value.strip("'\"") ~ "'")) -%}
      {% else %}
        {%- do formatted_values.append((get_binding_char(), value)) -%}
      {% endif %}
    {% else %}
      {%- do formatted_values.append((get_binding_char(), value)) -%}
    {% endif %}
  {%- endfor %}

  {{ return(formatted_values) }}
{% endmacro %}


{#
  Macro Purpose:
  --------------
  This macro is designed to load CSV data into a Presto table, ensuring that each value is cast to the appropriate
  data type based on either automatically detected types or user-specified types.

  Why This Macro is Needed:
  -------------------------
  - Presto requires explicit data type casting for certain values during insertion. For example, when inserting
    CHAR, VARCHAR, or JSON types, the values must be formatted correctly.
  - Typically, dbt detects the data types from the CSV data automatically, but dbt also allows the user to override
    the column types via the `column_types` setting in the `dbt_project.yml` file.

  Macro Workflow:
  ---------------
  1. The macro reads the data from the CSV file and detects the data types of each column.
  2. If `column_types` is provided in `dbt_project.yml`, the macro applies the custom types to the columns.
  3. It ensures proper formatting for each value (e.g., casting strings as CHAR, handling JSON objects, etc.).
  4. The formatted values are then inserted into the Presto table, ensuring compliance with Presto’s data type
     requirements.

  Benefit:
  --------
  This macro ensures that the seed data from CSV files is accurately loaded into Presto, with each column having the
  correct data type whether it is automatically detected or manually specified.
#}

{% macro watsonx_presto__load_csv_rows(model, agate_table) %}
  {% set column_override = model['config'].get('column_types', {}) %}
  {% set types = [] %}

  {%- for col_name in agate_table.column_names -%}
      {%- set inferred_type = adapter.convert_type(agate_table, loop.index0) -%}
      {%- set type = column_override.get(col_name, inferred_type) -%}
      {%- do types.append(type) -%}
  {%- endfor -%}

  {% set batch_size = get_batch_size() %}

  {% set cols_sql = get_seed_column_quoted_csv(model, agate_table.column_names) %}
  {% set statements = [] %}

  {% for chunk in agate_table.rows | batch(batch_size) %}
      {% set bindings = [] %}

      {% set sql %}
          insert into {{ this.render() }} ({{ cols_sql }}) values
          {% for row in chunk -%}
              ({%- for formatted_value in generate_bindings(row, types) -%}
                  {%- if formatted_value.0 is not none  -%}
                  {{ formatted_value.0 }}
                  {%- do bindings.append(formatted_value.1) -%}
                  {%- else -%}
                  {{ formatted_value.1 }}
                  {%- endif -%}
                  {%- if not loop.last%},{%- endif %}
              {%- endfor -%})
              {%- if not loop.last%},{%- endif %}
          {%- endfor %}
      {% endset %}

      {% do adapter.add_query(sql, bindings=bindings, abridge_sql_log=True) %}

      {% if loop.index0 == 0 %}
          {% do statements.append(sql) %}
      {% endif %}
  {% endfor %}

  {# Return SQL so we can render it out into the compiled files #}
  {{ return(statements[0]) }}
{% endmacro %}


{% macro properties(properties) %}
  {%- if properties is not none -%}
      WITH (
          {%- for key, value in properties.items() -%}
            {{ key }} = {{ value }}
            {%- if not loop.last -%}{{ ',\n  ' }}{%- endif -%}
          {%- endfor -%}
      )
  {%- endif -%}
{%- endmacro -%}


{% macro watsonx_presto__create_table_as(temporary, relation, sql) -%}
  {%- set _properties = config.get('properties') -%}
  create table {{ relation }}
    {{ properties(_properties) }}
  as (
    {{ sql }}
  );
{% endmacro %}


{% macro watsonx_presto__create_view_as(relation, sql) -%}
  create or replace view
    {{ relation }}
  as
    {{ sql }}
  ;
{% endmacro %}


{% macro watsonx_presto__drop_relation(relation) -%}
  {% call statement('drop_relation', auto_begin=False) -%}
    drop {{ relation.type }} if exists {{ relation }}
  {%- endcall %}
{% endmacro %}


{# see this issue: https://github.com/fishtown-analytics/dbt/issues/2267 #}
{% macro watsonx_presto__information_schema_name(database) -%}
  {%- if database -%}
    {{ database }}.information_schema
  {%- else -%}
    information_schema
  {%- endif -%}
{%- endmacro %}


{# On Presto, 'cascade' isn't supported so we have to manually cascade. #}
{% macro watsonx_presto__drop_schema(relation) -%}
  {% for row in list_relations_without_caching(relation) %}
    {% set rel_db = row[0] %}
    {% set rel_identifier = row[1] %}
    {% set rel_schema = row[2] %}
    {% set rel_type = api.Relation.get_relation_type(row[3]) %}
    {% set existing = api.Relation.create(database=rel_db, schema=rel_schema, identifier=rel_identifier, type=rel_type) %}
    {% do drop_relation(existing) %}
  {% endfor %}
  {%- call statement('drop_schema') -%}
    drop schema if exists {{ relation }}
  {% endcall %}
{% endmacro %}


{% macro watsonx_presto__rename_relation(from_relation, to_relation) -%}
  {% call statement('rename_relation') -%}
    alter {{ from_relation.type }} {{ from_relation }} rename to {{ to_relation }}
  {%- endcall %}
{% endmacro %}


{% macro watsonx_presto__get_batch_size() %}
  {{ return(1000) }}
{% endmacro %}


{% macro watsonx_presto__list_schemas(database) -%}
  {% call statement('list_schemas', fetch_result=True, auto_begin=False) %}
    select distinct schema_name
    from {{ information_schema_name(database) }}.schemata
  {% endcall %}
  {{ return(load_result('list_schemas').table) }}
{% endmacro %}


{% macro watsonx_presto__check_schema_exists(information_schema, schema) -%}
  {% call statement('check_schema_exists', fetch_result=True, auto_begin=False) -%}
        select count(*)
        from {{ information_schema }}.schemata
        where catalog_name = '{{ information_schema.database }}'
          and schema_name = '{{ schema }}'
  {%- endcall %}
  {{ return(load_result('check_schema_exists').table) }}
{% endmacro %}
