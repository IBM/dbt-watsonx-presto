import unittest
from multiprocessing import get_context
import dbt.flags as flags
from dbt.adapters.watsonx_presto import Watsonx_PrestoAdapter

from .utils import config_from_parts_or_dicts, mock_connection


class TestPrestoAdapter(unittest.TestCase):

    def setUp(self):
        flags.STRICT_MODE = True

        profile_cfg = {
            'outputs': {
                'test': {
                    'type': 'watsonx_presto',
                    'catalog': 'prestodb',
                    'host': 'database',
                    'port': 5439,
                    'schema': 'dbt_test_schema',
                    'method': 'none',
                    'user': 'presto_user',
                    'ssl_verify': '/path/to/cert',
                    'http_scheme': 'http',
                }
            },
            'target': 'test'
        }

        project_cfg = {
            'name': 'X',
            'version': '0.1',
            'profile': 'test',
            'project-root': '/tmp/dbt/does-not-exist',
            'quoting': {
                'identifier': False,
                'schema': True,
            },
            'config-version': 2
        }

        self.config = config_from_parts_or_dicts(project_cfg, profile_cfg)


    @property
    def adapter(self):
        self._adapter = Watsonx_PrestoAdapter(self.config, get_context("spawn"))
        return self._adapter

    def test_acquire_connection(self):
        connection = self.adapter.acquire_connection('dummy')

        connection.handle

        self.assertEqual(connection.state, 'open')
        self.assertNotEqual(connection.handle, None)

    def test_cancel_open_connections_empty(self):
        self.assertEqual(len(list(self.adapter.cancel_open_connections())), 0)

    def test_cancel_open_connections_master(self):
        key = self.adapter.connections.get_thread_identifier()
        self.adapter.connections.thread_connections[key] = mock_connection(
            'master')
        self.assertEqual(len(list(self.adapter.cancel_open_connections())), 0)
