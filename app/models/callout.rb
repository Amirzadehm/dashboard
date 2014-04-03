class Callout < ActiveRecord::Base
  belongs_to :script_level
  
  CSV_HEADERS = 
  {
      :element_id => 'element_id',
      :text => 'text',
      :at => 'at',
      :my => 'my',
      :script_id => 'script_id',
      :level_num => 'level_num',
      :qtip_config => 'qtip_config'
  }
  
  # Use the zero byte as the quote character to allow importing double quotes
  #   via http://stackoverflow.com/questions/8073920/importing-csv-quoting-error-is-driving-me-nuts
  CSV_IMPORT_OPTIONS = { col_sep: "\t", headers: true, :quote_char => "\x00" }
  
  def self.find_or_create_all_from_tsv!(filename)
    created = []
    CSV.read(filename, CSV_IMPORT_OPTIONS).each do |row|
      created << self.first_or_create_from_tsv_row!(row)
    end
    created
  end

  def self.first_or_create_from_tsv_row!(row_data)
    level = Level.where(:level_num => row_data[CSV_HEADERS[:level_num]]).first
    script_level = (level ? ScriptLevel.where(:level_id => level.id, :script_id => row_data[CSV_HEADERS[:script_id]]).first : nil)
    
    unless level && script_level
      puts "Error creating callout for level_num: #{row_data[CSV_HEADERS[:level_num]]} script_id: #{row_data[CSV_HEADERS[:script_id]]}"
      return nil
    end
    
    params = {element_id: row_data[CSV_HEADERS[:element_id]],
            text: row_data[CSV_HEADERS[:text]],
            qtip_at: row_data[CSV_HEADERS[:at]],
            qtip_my: row_data[CSV_HEADERS[:my]],
            qtip_config: row_data[CSV_HEADERS[:qtip_config]],
            script_level: script_level}
    Callout.where(params).first_or_create!
  end
end
