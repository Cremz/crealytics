require File.expand_path('lib/combiner',File.dirname(__FILE__))
require 'csv'
require 'date'

def latest(name)
  files = Dir["#{ ENV["HOME"] }/workspace/*#{name}*.txt"]

  files.sort_by! do |file|
    last_date = /\d+-\d+-\d+_[[:alpha:]]+\.txt$/.match file
    last_date = last_date.to_s.match /\d+-\d+-\d+/

    date = DateTime.parse(last_date.to_s)
    date
  end

  throw RuntimeError if files.empty?

  files.last
end

class String
	def from_german_to_f
		self.gsub(',', '.').to_f
	end
end

class Float
	def to_german_s
		self.to_s.gsub('.', ',')
	end
end

class Modifier

	KEYWORD_UNIQUE_ID = 'Keyword Unique ID'
	LAST_VALUE_WINS = ['Account ID', 'Account Name', 'Campaign', 'Ad Group', 'Keyword', 'Keyword Type', 'Subid', 'Paused', 'Max CPC', 'Keyword Unique ID', 'ACCOUNT', 'CAMPAIGN', 'BRAND', 'BRAND+CATEGORY', 'ADGROUP', 'KEYWORD']
	LAST_REAL_VALUE_WINS = ['Last Avg CPC', 'Last Avg Pos']
	INT_VALUES = ['Clicks', 'Impressions', 'ACCOUNT - Clicks', 'CAMPAIGN - Clicks', 'BRAND - Clicks', 'BRAND+CATEGORY - Clicks', 'ADGROUP - Clicks', 'KEYWORD - Clicks']
	FLOAT_VALUES = ['Avg CPC', 'CTR', 'Est EPC', 'newBid', 'Costs', 'Avg Pos']

  LINES_PER_FILE = 120000

	def initialize(saleamount_factor, cancellation_factor)
		@saleamount_factor = saleamount_factor
		@cancellation_factor = cancellation_factor
	end

	def modify(output, input)
		input = sort(input)

		input_enumerator = lazy_read(input)

		combiner = Combiner.new do |value|
			value[KEYWORD_UNIQUE_ID]
		end.combine(input_enumerator)

		merger = Enumerator.new do |yielder|
			while true
				begin
					list_of_rows = combiner.next
					merged = combine_hashes(list_of_rows)
					yielder.yield(combine_values(merged))
				rescue StopIteration
					break
				end
			end
		end

    done = false
    file_index = 0
    file_name = output.gsub('.txt', '')
    while not done do
		  CSV.open(file_name + "_#{file_index}.txt", "wb", { :col_sep => "\t", :headers => :first_row, :row_sep => "\r\n" }) do |csv|
			  headers_written = false
        line_count = 0
			  while line_count < LINES_PER_FILE
				  begin
					  merged = merger.next
					  if not headers_written
						  csv << merged.keys
						  headers_written = true
              line_count +=1
					  end
					  csv << merged
            line_count +=1
				  rescue StopIteration
            done = true
					  break
				  end
			  end
        file_index += 1
		  end
    end
	end

	private

	def combine(merged)
		result = []
		merged.each do |_, hash|
			result << combine_values(hash)
		end
		result
	end

	def combine_values(hash)
		LAST_VALUE_WINS.each do |key|
			hash[key] = hash[key].last
		end
		LAST_REAL_VALUE_WINS.each do |key|
			hash[key] = hash[key].select {|v| not (v.nil? or v == 0 or v == '0' or v == '')}.last
		end
		INT_VALUES.each do |key|
			hash[key] = hash[key][0].to_s
		end
		FLOAT_VALUES.each do |key|
			hash[key] = hash[key][0].from_german_to_f.to_german_s
		end
		['number of commissions'].each do |key|
			hash[key] = (@cancellation_factor * hash[key][0].from_german_to_f).to_german_s
		end
		['Commission Value', 'ACCOUNT - Commission Value', 'CAMPAIGN - Commission Value', 'BRAND - Commission Value', 'BRAND+CATEGORY - Commission Value', 'ADGROUP - Commission Value', 'KEYWORD - Commission Value'].each do |key|
			hash[key] = (@cancellation_factor * @saleamount_factor * hash[key][0].from_german_to_f).to_german_s
		end
		hash
	end

	def combine_hashes(list_of_rows)
		keys = []
		list_of_rows.each do |row|
			next if row.nil?
			row.headers.each do |key|
				keys << key
			end
		end
		result = {}
		keys.each do |key|
			result[key] = []
			list_of_rows.each do |row|
				result[key] << (row.nil? ? nil : row[key])
			end
		end
		result
	end

	DEFAULT_CSV_OPTIONS = { :col_sep => "\t", :headers => :first_row }

	def parse(file)
		CSV.read(file, DEFAULT_CSV_OPTIONS)
	end

	def lazy_read(file)
		Enumerator.new do |yielder|
			CSV.foreach(file, DEFAULT_CSV_OPTIONS) do |row|
				yielder.yield(row)
			end
		end
	end

	def write(content, headers, output)
		CSV.open(output, "wb", { :col_sep => "\t", :headers => :first_row, :row_sep => "\r\n" }) do |csv|
			csv << headers
			content.each do |row|
				csv << row
			end
		end
	end

	public
	def sort(file)
		output = "#{file}.sorted"
		content_as_table = parse(file)
		headers = content_as_table.headers
		index_of_key = headers.index('Clicks')
		content = content_as_table.sort_by { |a| -a[index_of_key].to_i }
		write(content, headers, output)
		return output
	end
end

modified = input = latest('project_2012-07-27_2012-10-10_performancedata')
modification_factor = 1
cancellaction_factor = 0.4
modifier = Modifier.new(modification_factor, cancellaction_factor)
modifier.modify(modified, input)

puts "DONE modifying"
