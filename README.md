TODO: Write more instructions.

# Installation

Put `metrics-cloudwatch.rb` into `/etc/sensu/plugins`.

# Requirement

`aws-sdk-core` gem.

With sensu embedded ruby, do

```
/opt/sensu/embedded/bin/gem install aws-sdk-core
```

# Usage

```
Usage: metrics-cloudwatch.rb (options)
    -k ACCESS_KEY_ID,                AWS access key id.
        --access-key-id
    -d DIMENSION_NAME_1:DIMENSION_VALUE_1,DIMENSION_NAME_2:DIMENSION_VALUE_2...,
        --dimensions                 CloudWatch dimension names and values, seperated by commas. (required)
        --end-time-offset N          Get metric statistics specified seconds ago.
    -i, --interval N                 Time interval between start and end for CloudWatch statistics.
    -m METRIC_NAME_1:TYPE,METRIC_NAME_2:TYPE...,
        --metrics                    CloudWatch metric names and statistics types, seperated by commas. (required)
    -n, --namespace NAMESPACE        CloudWatch namespace. (required)
    -N, --newest-only                Specify if want newest datapoint only.
    -p, --period N                   CloudWatch datapoint period.
        --profile PROFILE            Profile name of AWS shared credential file entry.
    -r, --region REGION              AWS region.
    -S, --scheme SCHEME              Metric naming scheme, text to prepend to dimension and metric names.
    -s SECRET_ACCESS_KEY,            AWS secret access key.
        --secret-access-key
```

# Example

```
% be ruby metrics-cloudwatch.rb --namespace AWS/ELB --dimensions LoadBalancerName:orenoelb --metrics Latency:Average,RequestCount:Sum,UnHealthyHostCount:Average,HealthyHostCount:Average,HTTPCode_Backend_2XX:Sum,HTTPCode_Backend_4XX:Sum,HTTPCode_Backend_5XX:Sum,HTTPCode_ELB_4XX:Sum,HTTPCode_ELB_5XX:Sum --scheme orenonode --newest-only
orenonode.LoadBalancerName.myloadbalancer.Latency.Average 0.013829676310221353 1418969340
orenonode.LoadBalancerName.myloadbalancer.RequestCount.Sum 15.0 1418969340
orenonode.LoadBalancerName.myloadbalancer.UnHealthyHostCount.Sum 0.0 1418969340
orenonode.LoadBalancerName.myloadbalancer.HealthyHostCount.Sum 16.0 1418969340
orenonode.LoadBalancerName.myloadbalancer.HTTPCode_Backend_2XX.Sum 15.0 1418969340
```
