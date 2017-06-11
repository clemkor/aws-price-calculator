#! /usr/bin/env ruby

require 'active_support/all'
require 'yaml'
require 'aws-sdk'
require 'fileutils'

instance_type = ENV['INSTANCE_TYPE'] || 'g2.8xlarge'
regions_file_path = 'data/001-regions/all.yml'
credentials_file_path = 'secrets/aws/credentials.yml'

output_directory_path = "data/002-spot-pricing/#{instance_type}"

regions = YAML.load_file(regions_file_path)['regions']
credentials = YAML.load_file(credentials_file_path)

FileUtils.mkpath(output_directory_path)

regions.each do |region|
  client = Aws::EC2::Client.new(
      region: region,
      credentials: Aws::Credentials.new(
          credentials['access_key_id'],
          credentials['secret_access_key']))

  spot_price_history = client.describe_spot_price_history(
      start_time: 1.week.ago,
      end_time: Time.now,
      instance_types: [
          instance_type
      ],
      product_descriptions: [
          "Linux/UNIX (Amazon VPC)"
      ]).inject([]) do |history_entries, page|
    history_entries.concat(page[:spot_price_history])
  end

  spot_price_history_by_availability_zone =
      spot_price_history.group_by(&:availability_zone)

  spot_price_points_by_availability_zone =
      spot_price_history_by_availability_zone
          .transform_values do |zone_price_history|
        zone_price_history.map do |history_entry|
          {
              'price' => history_entry[:spot_price].to_f,
              'timestamp' => history_entry[:timestamp].iso8601
          }
        end
      end

  File.open(File.join(output_directory_path, "#{region}.yml"), 'w') do |f|
    f.write(YAML.dump(
        {'spot_price_points' => spot_price_points_by_availability_zone}))
  end
end
