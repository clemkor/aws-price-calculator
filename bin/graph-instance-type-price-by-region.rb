#! /usr/bin/env ruby

require 'active_support/all'
require 'yaml'
require 'daru'
require 'pp'

instance_type = ENV['INSTANCE_TYPE'] || 'g2.8xlarge'
regions_file_path = 'data/001-regions/all.yml'

output_directory_path = "data/003-graphs/#{instance_type}"

region_configuration = YAML.load_file(regions_file_path)
regions = region_configuration['regions']

FileUtils.mkpath(output_directory_path)

regions[0..1].each do |region|
  region_spot_price_points_file_path =
      "data/002-spot-pricing/#{instance_type}/#{region}.yml"

  spot_price_points_by_zone =
      YAML.load_file(region_spot_price_points_file_path)['spot_price_points']

  spot_price_points_by_zone.each do |zone, spot_price_points|
    prices = spot_price_points.map { |price_point| price_point['price'] }
    index = spot_price_points.map { |price_point| price_point['timestamp'] }

    vector = Daru::Vector.new(prices, index: index, name: zone)

    puts vector.plot(type: :scatter)
  end
end
