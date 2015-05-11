#!/usr/bin/env ruby

require "sensu-plugin/metric/cli"
require "aws-sdk-core"

class MetricsCloudWatch < Sensu::Plugin::Metric::CLI::Graphite
  VERSION = "0.2.0"

  option :profile,
    description: "Profile name of AWS shared credential file entry.",
    long:        "--profile PROFILE"

  option :access_key_id,
    description: "AWS access key id.",
    short:       "-k ACCESS_KEY_ID",
    long:        "--access-key-id ACCESS_KEY_ID"

  option :secret_access_key,
    description: "AWS secret access key.",
    short:       "-s SECRET_ACCESS_KEY",
    long:        "--secret-access-key SECRET_ACCESS_KEY"

  option :region,
    description: "AWS region.",
    short:       "-r REGION",
    long:        "--region REGION"

  option :namespace,
    description: "CloudWatch namespace.",
    short:       "-n NAMESPACE",
    long:        "--namespace NAMESPACE",
    required:    true

  option :metrics,
    description: "CloudWatch metric names and statistics types, seperated by commas.",
    short:       "-m METRIC_NAME_1:TYPE,METRIC_NAME_2:TYPE...",
    long:        "--metrics METRIC_NAME_1:TYPE,METRIC_NAME_2:TYPE...",
    required:    true

  option :dimensions,
    description: "CloudWatch dimension names and values, seperated by commas.",
    short:       "-d DIMENSION_NAME_1:DIMENSION_VALUE_1,DIMENSION_NAME_2:DIMENSION_VALUE_2...",
    long:        "--dimensions DIMENSION_NAME_1:DIMENSION_VALUE_1,DIMENSION_NAME_2:DIMENSION_VALUE_2..."

  option :interval,
    description: "Time interval between start and end for CloudWatch statistics.",
    short:       "-i N",
    long:        "--interval N",
    default:     300,
    proc:        proc {|v| v.to_i}

  option :end_time_offset,
    description: "Get metric statistics specified seconds ago.",
    long:        "--end-time-offset N",
    default:     0,
    proc:        proc {|v| v.to_i}

  option :period,
    description: "CloudWatch datapoint period.",
    short:       "-p N",
    long:        "--period N",
    default:     60,
    proc:        proc {|v| v.to_i}

  option :scheme,
    description: "Metric naming scheme, text to prepend to dimension and metric names.",
    short:       "-S SCHEME",
    long:        "--scheme SCHEME",
    default:     ""

  option :newest_only,
    description: "Specify if want newest datapoint only.",
    type:        :boolean,
    short:       "-N",
    long:        "--newest-only"

  option :flatten_dimensions,
    description: "Outputs each dimension as line.",
    type:        :boolean,
    short:       "-F",
    long:        "--flatten-dimensions"

  def run
    config[:metrics].split(",").each do |metric|
      metric_name, statistics = metric.split(":")

      if config[:flatten_dimensions]
        dimensions.each do |dimension|
          params = {
            namespace:   config[:namespace],
            metric_name: metric_name,
            start_time:  start_time,
            end_time:    end_time,
            period:      config[:period],
            statistics:  [statistics],
            dimensions:  [dimension],
          }

          datapoints = get_datapoints(params)
          output_datapoints(datapoints, metric_name, statistics, [dimension[:name], dimension[:value]])
        end
      else
        params = {
          namespace:   config[:namespace],
          metric_name: metric_name,
          start_time:  start_time,
          end_time:    end_time,
          period:      config[:period],
          statistics:  [statistics],
          dimensions:  dimensions
        }

        datapoints = get_datapoints(params)
        output_datapoints(datapoints, metric_name, statistics, (dimensions.map {|d| [d[:name], d[:value]]} if dimensions))
      end
    end

    ok
  rescue => ex
    puts ex.backtrace
    unknown "Error: #{ex}"
  end

  private

  def aws_configuration
    hash = {}

    [:profile, :access_key_id, :secret_access_key, :region].each do |option|
      hash.update(option => config[option]) if config[option]
    end

    hash.update(region: own_region) if hash[:region].nil?
    hash
  end

  def own_region
    @own_region ||= begin
      require "net/http"

      timeout 3 do
        Net::HTTP.get("169.254.169.254", "/latest/meta-data/placement/availability-zone").chop
      end
    rescue
      nil
    end
  end

  def cloudwatch_client
    @cloudwatch_client ||= Aws::CloudWatch::Client.new aws_configuration
  end

  def dimensions
    return if config[:dimensions].nil?

    @dimensions ||= config[:dimensions].split(",").map do |dimension|
      kv = dimension.split(":")

      {
        name:  kv.first,
        value: kv.last,
      }
    end
  end

  def end_time
    @end_time ||= Time.now - config[:end_time_offset]
  end

  def start_time
    @start_time ||= end_time - config[:interval]
  end

  def output_datapoints(datapoints, metric_name, statistics, dimension)
    datapoints.each do |datapoint|
      next if datapoint.nil?

      paths = [
        config[:scheme],
        dimension,
        metric_name,
        statistics,
      ]

      path         = paths.flatten.compact.reject(&:empty?).join(".")
      metric_value = datapoint[statistics.downcase.intern]
      timestamp    = datapoint[:timestamp].to_i

      output [path, metric_value, timestamp].join(" ")
    end
  end

  def get_datapoints(params)
    response = cloudwatch_client.get_metric_statistics(params.reject {|k, v| v.nil?})

    unknown "CloudWatch GetMetricStatics unsuccessful." unless response.successful?

    if config[:newest_only]
      [response.datapoints.sort_by {|datapoint| datapoint[:timestamp]}.last]
    else
      response.datapoints
    end
  end
end
