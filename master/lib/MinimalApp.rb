#!/usr/bin/env ruby
# encoding: utf-8

require 'sushi_fabric'
require_relative 'global_variables'
include GlobalVariables

require 'csv'
class MinimalApp < SushiFabric::SushiApp
  def initialize
    super
    @employee = true
    @name = 'MinimalApp'
    @description = "test applicaiton #{GlobalVariables::SUSHI}"
    @analysis_category = 'Stats'
    @params['cores'] = '1'
    @params['ram'] = '10'
    @params['scratch'] = '10'
    @required_columns = ['Name']
    @required_params = []
  end
  def next_dataset
    {
      'Name'=>@dataset['Name'],
      'Result [File]'=>File.join(@result_dir, @dataset['Name'].to_s + '.txt')
    }
  end
  def commands
    commands = "touch #{@dataset['Name']}.txt\n"
  end
end

