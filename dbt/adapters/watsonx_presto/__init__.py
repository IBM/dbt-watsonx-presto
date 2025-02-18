from dbt.adapters.watsonx_presto.connections import PrestoConnectionManager  # noqa
from dbt.adapters.watsonx_presto.connections import PrestoCredentials
from dbt.adapters.watsonx_presto.column import PrestoColumn  # noqa
from dbt.adapters.watsonx_presto.impl import Watsonx_PrestoAdapter

from dbt.adapters.base import AdapterPlugin
from dbt.include import watsonx_presto


Plugin = AdapterPlugin(
    adapter=Watsonx_PrestoAdapter,
    credentials=PrestoCredentials,
    include_path=watsonx_presto.PACKAGE_PATH)
