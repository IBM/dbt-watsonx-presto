## dbt-watsonx-presto

[dbt](https://www.getdbt.com/) enables data analysts and engineers to transform their data using the same practices that software engineers use to build applications.

dbt is the T in ELT. Organize, cleanse, denormalize, filter, rename, and pre-aggregate the raw data in your warehouse so that it's ready for analysis.

### Overview

The `dbt-watsonx-presto` adapter uses [Presto](https://prestodb.io/) as the underlying SQL query engine to enable powerful data transformations and query federation across diverse data sources. With Presto, you can connect to multiple data systems (via available connectors) through a single dbt connection and process SQL queries efficiently at scale.

Transformations defined in dbt are passed to Presto, which executes these SQL queries by translating them into queries specific to the connected systems. Presto then creates tables, builds views, or manipulates data as defined by your dbt project.

This repository is an evolution of the [dbt-presto](https://github.com/dbt-labs/dbt-presto) adapter, specifically designed for seamless compatibility with both [open-source Presto](https://prestodb.io/) and IBM [watsonx.data Presto](https://www.ibm.com/products/watsonx-data) instances.


Read the official documentation for using watsonx.data with dbt-watsonx-presto -

- [Documentation for IBM Cloud and SaaS offerrings](https://cloud.ibm.com/docs/watsonxdata?topic=watsonxdata-dbt_watsonx_presto)
- [Documentation for IBM watsonx.data software](https://ibmdocs-test.dcs.ibm.com/docs/en/SSDZ38_2.1.x_test?topic=integration-data-build-tool-adapter-presto)

### Getting started

- [Install dbt](https://docs.getdbt.com/docs/core/installation-overview)
- Read the [introduction](https://docs.getdbt.com/docs/introduction) and [viewpoint](https://docs.getdbt.com/community/resources/viewpoint)

### Installation
To install the `dbt-watsonx-presto` plugin, use pip:
```
$ pip install dbt-watsonx-presto
```

### Configuration
#### Setting Up Your Profile

To connect dbt Core to your Presto clusters, configure the `profiles.yml` file located in the `.dbt/` directory of your home directory. :

**Example profiles.yml entry:**
```
my_project:
  outputs:
    software:
      type: watsonx_presto
      method: BasicAuth
      user: username
      password: password
      host:  localhost
      port: 443
      database: analytics
      schema: dbt_drew
      threads: 8
      ssl_verify: path/to/certificate
      
    saas:
      type: watsonx_presto
      method: BasicAuth
      user: username
      password: api_key
      host: 127.0.0.1
      port: 8080
      database: analytics
      schema: dbt_drew
      threads: 8
      ssl_verify: true
      
  target: software
```
For more detailed instructions on configuring your profiles, refer [configuring dbt-watsonx-presto](https://ibmdocs-test.dcs.ibm.com/docs/en/SSDZ38_2.1.x_test?topic=presto-configuration-setting-up-your-profile).

#### Presto-Specific Configuration
For Presto-specific configurations, such as advanced session properties or Presto connectors, consult the Presto Configuration Guide.

### Contributing
We welcome contributions to the dbt-watsonx-presto project. Here’s how you can help:

- Report Issues: If you encounter bugs or have feature requests, please submit them via [GitHub Issues](https://github.com/IBM/dbt-watsonx-presto/issues).
- Submit Code: Follow the [Contributing Guide](https://github.com/IBM/dbt-watsonx-presto/blob/main/CONTRIBUTING.md) to submit pull requests with improvements or new features.


### License
By contributing to dbt-watsonx-presto, you agree that your contributions will be licensed under the [Apache License Version 2.0 (APLv2)](https://github.com/IBM/dbt-watsonx-presto/blob/main/LICENSE).