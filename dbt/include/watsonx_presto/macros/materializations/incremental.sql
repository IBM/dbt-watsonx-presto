
{% materialization incremental, adapter='watsonx_presto' -%}
  {{ exceptions.raise_not_implemented(
    'incremental materialization not implemented for '+adapter.type())
  }}
{% endmaterialization %}
