# Welcome to Winlogbeat 7.5.2

Winlogbeat ships Windows event logs to Elasticsearch or Logstash.

## Getting Started

To get started with Winlogbeat, you need to set up Elasticsearch on
your localhost first. After that, start Winlogbeat with:

     ./winlogbeat -c winlogbeat.yml -e

This will start Winlogbeat and send the data to your Elasticsearch
instance. To load the dashboards for Winlogbeat into Kibana, run:

    ./winlogbeat setup -e

For further steps visit the
[Getting started](https://www.elastic.co/guide/en/beats/winlogbeat/7.5/winlogbeat-getting-started.html) guide.

## Documentation

Visit [Elastic.co Docs](https://www.elastic.co/guide/en/beats/winlogbeat/7.5/index.html)
for the full Winlogbeat documentation.

## Release notes

https://www.elastic.co/guide/en/beats/libbeat/7.5/release-notes-7.5.2.html
