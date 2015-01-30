#!/usr/bin/env ruby
# encoding: utf-8

require 'sushi_fabric'
require_relative 'global_variables'
include GlobalVariables

class MpileupApp <  SushiFabric::SushiApp
  def initialize
    super
    @name = 'samtools mpileup'
    @params['process_mode'] = 'DATASET'
    @analysis_category = 'Variant_Analysis'
    @description =<<-EOS
Variant analysis with samtools/bcftools.<br/>
The analysis runs the 3 commands: samtools mpileup, bcftools call, bcftools filter<br/>
<a href='http://www.htslib.org/doc/samtools-1.1.html'>samtools manual/</a><br>
<a href='http://www.htslib.org/doc/bcftools-1.1.html'>bcftools manual/</a><br>
EOS
    @required_columns = ['Name','BAM','BAI', 'build']
    @required_params = ['name', 'paired']
    @params['cores'] = '8'
    @params['ram'] = '30'
    @params['scratch'] = '100'
    @params['paired'] = false
    @params['name'] = 'Mpileup_Variants'
    @params['build'] = ref_selector
    @params['region'] = ""
    @params['region', 'description'] = 'The region of the genome. You can give either a chromosome name or a region on a chromosome like chr1:1000-2000'
    @params['mpileupOptions'] = '--skip-indels --output-tags DP,DV,DPR,INFO/DPR,DP4,SP'
    @params['mpileupOptions', 'description'] = 'The options to the samtools mpileup command'
    @params['callOptions'] = '--multiallelic-caller --keep-alts --variants-only'
    @params['callOptions', 'description'] = 'The options to <a href=http://www.htslib.org/doc/bcftools-1.1.html#call>bcftools call</a>'
    @params['filterOptions'] = '--include "MIN(DP)>5"'
    @params['filterOptions', 'description'] = 'The options to <a href=http://www.htslib.org/doc/bcftools-1.1.html#filter>bcftools filter</a>'
    #@params['specialOptions'] = ''
    @params['mail'] = ""
  end
  def next_dataset
    report_dir = File.join(@result_dir, @params['name'])
    {'Name'=>@params['name'],
     'VCF [File]'=>File.join(@result_dir, "#{@params['name']}.vcf.gz"),
     'TBI [File]'=>File.join(@result_dir, "#{@params['name']}.vcf.gz.tbi"),
     'IGV Starter [Link]'=>File.join(@result_dir, "#{@params['name']}-igv.jnlp"),
     'Report [File]'=>report_dir,
     'Html [Link]'=>File.join(report_dir, '00index.html'),
     'Species'=>@dataset['Species'],
     'build'=>@params['build'],
     'IGV Starter [File]'=>File.join(@result_dir, "#{@params['name']}-igv.jnlp"),
     'IGV Session [File]'=>File.join(@result_dir, "#{@params['name']}-igv.xml")
    }
  end
  def set_default_parameters
    @params['build'] = @dataset[0]['build']
    if dataset_has_column?('paired')
      @params['paired'] = @dataset[0]['paired']
    end
  end

  def commands
    command = "/usr/local/ngseq/bin/R --vanilla --slave<<  EOT\n"
    command << "GLOBAL_VARIABLES <<- '#{GLOBAL_VARIABLES}'\n"
    command << "R_SCRIPT_DIR <<- '#{R_SCRIPT_DIR}'\n"
    command<<  "source(file.path(R_SCRIPT_DIR, 'init.R'))\n"
    command << "config = list()\n"
    config = @params
    config.keys.each do |key|
      command << "config[['#{key}']] = '#{config[key]}'\n" 
    end
    command << "config[['dataRoot']] = '#{@gstore_dir}'\n"
    command << "config[['resultDir']] = '#{@result_dir}'\n"
    command << "output = list()\n"
    output = next_dataset
    output.keys.each do |key|
      command << "output[['#{key}']] = '#{output[key]}'\n" 
    end
    command<<  "inputDatasetFile = '#{@input_dataset_tsv_path}'\n"
    command<<  "runApp('mpileupApp', input=inputDatasetFile, output=output, config=config)\n"
    command<<  "EOT\n"
    command
  end
end

if __FILE__ == $0
  usecase = BamStatsApp.new

  usecase.project = "p1001"
  usecase.user = "masa"

  # set user parameter
  # for GUI sushi
  #usecase.params['process_mode'].value = 'SAMPLE'
  #usecase.params['build'] = 'TAIR10'
  #usecase.params['paired'] = true
  #usecase.params['cores'] = 2
  #usecase.params['node'] = 'fgcz-c-048'

  # also possible to load a parameterset csv file
  # mainly for CUI sushi
  usecase.parameterset_tsv_file = 'tophat_parameterset.tsv'
  #usecase.params['name'] = 'name'

  # set input dataset
  # mainly for CUI sushi
  usecase.dataset_tsv_file = 'tophat_dataset.tsv'

  # also possible to load a input dataset from Sushi DB
  #usecase.dataset_sushi_id = 1

  # run (submit to workflow_manager)
  usecase.run
  #usecase.test_run

end

