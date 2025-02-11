
{% materialization snapshot, adapter='watsonx_presto' -%}
  {{ exceptions.raise_not_implemented(
    'snapshot materialization not implemented for '+adapter.type())
  }}
{% endmaterialization %}
