namespace :ds do

  def sample_path(data_set)
    paths = []
    data_set.samples.each do |sample|
      sample.to_hash.each do |header, file|
        if (header.tag?('File') or header.tag?('Link')) and file !~ /http/
          paths << File.dirname(file)
        end
      end
    end
    paths.uniq!
    paths
  end

  desc "Check STAR BWA Bowtie datasets"
  task star_bwa_bowtie: :environment do
    puts ["project", "name", "#samples", "created_at", "link", "gstore_path", "#bams", "size [GB]"].join("\t")
    DataSet.all.each do |data_set|
      if data_set.name =~ /star/i or data_set.name =~ /bwa/i or data_set.name =~ /bowtie/i
        link = "https://fgcz-sushi.uzh.ch/data_set/p#{data_set.project.number}/#{data_set.id}"
        paths = sample_path(data_set)
        paths.delete('.')
        paths = paths.uniq.compact
        bams_size_total = 0
        dir_size_total = 0
        gstore_paths = []
        paths.each do |path|
          gstore_path = File.join("/srv/gstore/projects", path)
          gstore_paths << gstore_path
          bams_size = Dir[File.join(gstore_path, "*.bam")].to_a.length
          bams_size_total += bams_size
          com = "du -s #{gstore_path}"
          dir_size = if File.exist?(gstore_path)
                       `#{com}`.to_i
                     else
                       0
                     end
          dir_size_total += dir_size
        end
        dir_size_total = "%d" % (dir_size_total/1000000.0)
        puts [data_set.project.number, data_set.name, data_set.samples.length, data_set.created_at.to_s.split.first, link, gstore_paths.join(","), bams_size_total, dir_size_total].join("\t")
      end
    end
  end

  desc "Check root datasets"
  task roots: :environment do
    ds2nc = {}
    DataSet.all.each do |data_set|
      unless data_set.data_set
        # root data_set
        child_count = 0
        data_set.data_sets.each do |child|
          if child.name =~ /Fastqc/ or child.name =~ /FastqScreen/
            # nothing
          else
            child_count += 1
          end
        end
        ds2nc[data_set] = child_count
      end
    end
    puts ["project", "name", "#samples", "created_at", "link"].join("\t")
    ds2nc.sort_by{|data_set, child_count| data_set.project.number}.each do |data_set, child_count|
      link = "https://fgcz-sushi.uzh.ch/data_set/#{data_set.id}"
      puts [data_set.project.number, data_set.name, child_count, data_set.created_at.to_s.split.first, link].join("\t")
    end
  end

  desc "Check only data delivery datasets"
  task data_delivery_candidates: :environment do
    delivery_data_candidates = []
    DataSet.all.each do |data_set|
      unless data_set.data_set
        # root data_set
        flag = false
        data_set.data_sets.each do |child|
          if child.name =~ /Fastqc/ or child.name =~ /FastqScreen/
            # nothing
          else
            flag = true
            break
          end
        end
        unless flag
          delivery_data_candidates << data_set
        end
      end
    end
    puts ["project", "name", "#children", "created_at"].join("\t")
    delivery_data_candidates.each do |data_set|
      puts [data_set.project.number, data_set.name, data_set.data_sets.length, data_set.created_at.to_s.split.first].join("\t")
    end
    # check
    # p delivery_data_candidates.length
    # 980
  end

  desc "Save all datasets with date and SUSHIApp"
  task all_dataset_with_date_and_sushiapp: :environment do
    out_file = "all_datasets_with_sushiapp_#{Time.now.strftime("%Y-%m-%d")}.csv"
    headers = ["name", "project", "date", "SUSHIApp"]
    require 'csv'
    sushiapp2date = {}
    csv = CSV.generate("", headers: headers, write_headers: true, col_sep: ",") do |out|
      DataSet.all.each do |dataset|
        out << [dataset.name, dataset.project.number, dataset.updated_at.strftime("%Y-%m-%d"), dataset.sushi_app_name]
        if dataset.sushi_app_name
          sushiapp2date[dataset.sushi_app_name] ||= []
          sushiapp2date[dataset.sushi_app_name] << dataset.updated_at
        end
      end
    end
    File.write(out_file, csv)
    warn "# #{out_file} generated"

    out_file = "sushiapp_call_times.csv"
    headers = ["SUSHIApp", "call times", "latest"]
    csv = CSV.generate("", headers: headers, write_headers: true, col_sep: ",") do |out|
      sushiapp2date.keys.sort.each do |sushiapp|
        out << [sushiapp, sushiapp2date[sushiapp].length, sushiapp2date[sushiapp].max.strftime("%Y-%m-%d")]
      end
    end
    File.write(out_file, csv)
    warn "# #{out_file} generated"
  end

  desc "Save all datasets (samples)1"
  task dump_all_datasets_samples: :environment do
    out_file = "all_datasets_smaples_#{Time.now.strftime("%Y-%m-%d")}.csv"
    headers = ["name", "project", "samples"]
    require 'csv'
    csv = CSV.generate("", headers: headers, write_headers: true, col_sep: ",") do |out|
      DataSet.all.each do |dataset|
        row = [dataset.name, dataset.project.number]
        row << dataset.samples.map{|sample| sample.key_value}.join(":")
        out << row
      end
    end
    File.write(out_file, csv)
    warn "# #{out_file} generated"
  end

  desc "Save all datasets (samples)2"
  task dump_all_datasets_samples2: :environment do
    out_file = "all_datasets_smaples2_#{Time.now.strftime("%Y-%m-%d")}.txt"
    res = ActiveRecord::Base.connection.select_all("select * from samples;")
#    p res
    File.write(out_file, res.to_a.join(":"))
    warn "# #{out_file} generated"
  end


end
