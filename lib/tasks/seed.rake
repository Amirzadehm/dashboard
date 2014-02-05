require "csv"

namespace :seed do
  task videos: :environment do
    Video.connection.execute('truncate table videos')

    CSV.read('config/videos.csv', { col_sep: "\t", headers: true }).each do |row|
      Video.create!(key: row['Key'], youtube_code: row['YoutubeCode'], download: row['Download'])
    end

    Rake::Task["youtube:thumbnails"].invoke
  end

  task concepts: :environment do
    Concept.connection.execute('truncate table concepts')
    Concept.create!(name: 'sequence')
    Concept.create!(name: 'if', video: Video.find_by_key('if'))
    Concept.create!(name: 'if_else', video: Video.find_by_key('if_else'))
    Concept.create!(name: 'loop_times', video: Video.find_by_key('loop_times'))
    Concept.create!(name: 'loop_until', video: Video.find_by_key('loop_until'))
    Concept.create!(name: 'loop_while', video: Video.find_by_key('loop_while'))
    Concept.create!(name: 'loop_for', video: Video.find_by_key('loop_for'))
    Concept.create!(name: 'function', video: Video.find_by_key('function'))
    Concept.create!(name: 'parameters', video: Video.find_by_key('parameters'))
  end

  task games: :environment do
    Concept.connection.execute('truncate table games')

    Game.create!(name: 'Maze', app: 'maze', intro_video: Video.find_by_key('maze_intro'))
    Game.create!(name: 'Artist', app: 'turtle', intro_video: Video.find_by_key('artist_intro'))
    Game.create!(name: 'Artist2', app: 'turtle')
    Game.create!(name: 'Farmer', app: 'maze', intro_video: Video.find_by_key('farmer_intro'))
    Game.create!(name: 'Artist3', app: 'turtle')
    Game.create!(name: 'Farmer2', app: 'maze')
    Game.create!(name: 'Artist4', app: 'turtle')
    Game.create!(name: 'Farmer3', app: 'maze')
    Game.create!(name: 'Artist5', app: 'turtle')
    Game.create!(name: 'MazeEC', app: 'maze', intro_video: Video.find_by_key('maze_intro'))
    Game.create!(name: 'Unplug1', app: 'unplug')
    Game.create!(name: 'Unplug2', app: 'unplug')
    Game.create!(name: 'Unplug3', app: 'unplug')
    Game.create!(name: 'Unplug4', app: 'unplug')
    Game.create!(name: 'Unplug5', app: 'unplug')
    Game.create!(name: 'Unplug6', app: 'unplug')
    Game.create!(name: 'Unplug7', app: 'unplug')
    Game.create!(name: 'Unplug8', app: 'unplug')
    Game.create!(name: 'Unplug9', app: 'unplug')
    Game.create!(name: 'Unplug10', app: 'unplug')
    Game.create!(name: 'Unplug11', app: 'unplug')
  end

  COL_GAME = 'Game'
  COL_NAME = 'Name'
  COL_LEVEL = 'Level'
  COL_CONCEPTS = 'Concepts'
  COL_URL = 'Url'
  COL_SKIN = 'Skin'

  task scripts: :environment do
    c = Script.connection
    c.execute('truncate table script_levels')
    c.execute('truncate table scripts')

    game_map = Game.all.index_by(&:name)
    concept_map = Concept.all.index_by(&:name)

    sources = [
        { file: 'config/script.csv', params: { name: '20-hour', wrapup_video: nil, trophies: true, hidden: false }},
        { file: 'config/hoc_script.csv', params: { name: 'Hour of Code', wrapup_video: Video.find_by_key('hoc_wrapup'), trophies: false, hidden: false }},
        { file: 'config/ec_script.csv', params: { name: 'Edit Code', wrapup_video: Video.find_by_key('hoc_wrapup'), trophies: false, hidden: true }},
    ]
    sources.each do |source|
      script = Script.create!(source[:params])
      game_index = Hash.new{|h,k| h[k] = 0}

      CSV.read(source[:file], { col_sep: "\t", headers: true }).each_with_index do |row, index|
        game = game_map[row[COL_GAME].squish]
        puts "row #{index}: #{row.inspect}"
        level = Level.find_or_create_by_game_id_and_level_num(game.id, row[COL_LEVEL])
        level.name = row[COL_NAME]
        level.level_url ||= row[COL_URL]
        level.skin = row[COL_SKIN]

        if level.concepts.empty?
          if row[COL_CONCEPTS]
            row[COL_CONCEPTS].split(',').each do |concept_name|
              concept = concept_map[concept_name.squish]
              if !concept
                raise "missing concept '#{concept_name}'"
              else
                level.concepts << concept
              end
            end
          end
        end
        level.save!
        ScriptLevel.create!(script: script, level: level, chapter: (index + 1), game_chapter: (game_index[game.id] += 1))
      end
    end
  end

  CALLOUT_ELEMENT_ID = 'element_id'
  CALLOUT_TEXT = 'text'
  CALLOUT_AT = 'at'
  CALLOUT_MY = 'my'

  task callouts: :environment do
    Trophy.connection.execute('truncate table callouts')

    CSV.read('config/callouts.tsv', { col_sep: "\t", headers: true }).each do |row|
      Callout.create!(element_id: row[CALLOUT_ELEMENT_ID],
                      text: row[CALLOUT_TEXT],
                      qtip_at: row[CALLOUT_AT],
                      qtip_my: row[CALLOUT_MY])
    end
  end
  task trophies: :environment do
    # code in user.rb assumes that broze id: 1, silver id: 2 and gold id: 3.
    Trophy.connection.execute('truncate table trophies')
    Trophy.create!(name: 'Bronze', image_name: 'bronzetrophy.png')
    Trophy.create!(name: 'Silver', image_name: 'silvertrophy.png')
    Trophy.create!(name: 'Gold', image_name: 'goldtrophy.png')
  end
  
  task prize_providers: :environment do
    # placeholder data - id's are assumed to start at 1 so prizes below can be loaded properly
    PrizeProvider.connection.execute('truncate table prize_providers')
    PrizeProvider.create!(name: 'Apple iTunes', description_token: 'apple_itunes', url: 'http://www.apple.com/itunes/', image_name: 'itunes_card.jpg')
    PrizeProvider.create!(name: 'Dropbox', description_token: 'dropbox', url: 'http://www.dropbox.com/', image_name: 'dropbox_card.jpg')
    PrizeProvider.create!(name: 'Valve Portal', description_token: 'valve', url: 'http://www.valvesoftware.com/games/portal.html', image_name: 'portal2_card.png')
    PrizeProvider.create!(name: 'EA Origin Bejeweled 3', description_token: 'ea_bejeweled', url: 'https://www.origin.com/en-us/store/buy/181609/mac-pc-download/base-game/standard-edition-ANW.html', image_name: 'bejeweled_card.jpg')
    PrizeProvider.create!(name: 'EA Origin FIFA Soccer 13', description_token: 'ea_fifa', url: 'https://www.origin.com/en-us/store/buy/fifa-2013/pc-download/base-game/standard-edition-ANW.html', image_name: 'fifa_card.jpg')
    PrizeProvider.create!(name: 'EA Origin SimCity 4 Deluxe', description_token: 'ea_simcity', url: 'https://www.origin.com/en-us/store/buy/sim-city-4/pc-download/base-game/deluxe-edition-ANW.html', image_name: 'simcity_card.jpg')
    PrizeProvider.create!(name: 'EA Origin Plants vs. Zombies', description_token: 'ea_pvz', url: 'https://www.origin.com/en-us/store/buy/plants-vs-zombies/mac-pc-download/base-game/standard-edition-ANW.html', image_name: 'pvz_card.jpg')
    PrizeProvider.create!(name: 'DonorsChoose.org $750', description_token: 'donors_choose', url: 'http://www.donorschoose.org/', image_name: 'donorschoose_card.jpg')
    PrizeProvider.create!(name: 'DonorsChoose.org $250', description_token: 'donors_choose_bonus', url: 'http://www.donorschoose.org/', image_name: 'donorschoose_card.jpg')
    PrizeProvider.create!(name: 'Skype', description_token: 'skype', url: 'http://www.skype.com/', image_name: 'skype_card.jpg')
  end

  task ideal_solutions: :environment do
    Level.all.map do |level|
      level_source_id_count_map = Hash.new{|h,k| h[k] = {:level_source_id => k, :count => 0} }

      Activity.all.where(['level_id = ?', level.id]).order('id desc').limit(10000).each do |activity|
        level_source_id_count_map[activity.level_source_id][:count] += 1 if activity.best?
      end
      sorted_activities = level_source_id_count_map.values.sort_by {|v| -v[:count] }
      best = sorted_activities[0] if sorted_activities && sorted_activities.length > 0
      level.update_attributes(ideal_level_source_id: best[:level_source_id]) if best && best[:level_source_id]
    end
  end

  task :frequent_level_sources, [:freq_cutoff] => :environment do |t, args|
    # Among all the level_sources, find the ones that are submitted more than freq_cutoff times.
    puts args[:freq_cutoff]
    FrequentUnsuccessfulLevelSource.update_all('active = false')
    Activity.connection.execute('select level_source_id, level_id, count(*) as num_of_attempts from activities where test_result < 100 group by level_source_id order by num_of_attempts DESC').each do |level_source|
      if level_source[2] >= args[:freq_cutoff].to_i
        unsuccessful_level_source = FrequentUnsuccessfulLevelSource.where(
            level_source_id: level_source[0],
            level_id: level_source[1],
            num_of_attempts: level_source[2]).first_or_create;
        unsuccessful_level_source.active = true;
        unsuccessful_level_source.save!
      else
        break;
      end
    end
  end

  task dummy_prizes: :environment do
    # placeholder data
    Prize.connection.execute('truncate table prizes')
    TeacherPrize.connection.execute('truncate table teacher_prizes')
    TeacherBonusPrize.connection.execute('truncate table teacher_bonus_prizes')
    10.times do |n|
      string = n.to_s
      Prize.create!(prize_provider_id: 1, code: "APPL-EITU-NES0-000" + string)
      Prize.create!(prize_provider_id: 2, code: "DROP-BOX0-000" + string)
      Prize.create!(prize_provider_id: 3, code: "VALV-EPOR-TAL0-000" + string)
      Prize.create!(prize_provider_id: 4, code: "EAOR-IGIN-BEJE-000" + string)
      Prize.create!(prize_provider_id: 5, code: "EAOR-IGIN-FIFA-000" + string)
      Prize.create!(prize_provider_id: 6, code: "EAOR-IGIN-SIMC-000" + string)
      Prize.create!(prize_provider_id: 7, code: "EAOR-IGIN-PVSZ-000" + string)
      TeacherPrize.create!(prize_provider_id: 8, code: "DONO-RSCH-OOSE-750" + string)
      TeacherBonusPrize.create!(prize_provider_id: 9, code: "DONO-RSCH-OOSE-250" + string)
      Prize.create!(prize_provider_id: 10, code: "SKYP-ECRE-DIT0-000" + string)
    end
  end

  task :import_users, [:file] => :environment do |t, args|
    CSV.read(args[:file], { col_sep: "\t", headers: true }).each do |row|
      User.create!(
          provider: User::PROVIDER_MANUAL,
          name: row['Name'],
          username: row['Username'],
          password: row['Password'],
          password_confirmation: row['Password'],
          birthday: row['Birthday'].blank? ? nil : Date.parse(row['Birthday']))
    end
  end
  
  def import_prize_from_text(file, provider_id, col_sep)
    Rails.logger.info "Importing prize codes from: " + file + " for provider id " + provider_id.to_s
    CSV.read(file, { col_sep: col_sep, headers: false }).each do |row|
      if row[0].present?
        Prize.create!(prize_provider_id: provider_id, code: row[0])
      end
    end
  end

  task :import_itunes, [:file] => :environment do |t, args|
    import_prize_from_text(args[:file], 1, "\t")
  end

  task :import_dropbox, [:file] => :environment do |t, args|
    import_prize_from_text(args[:file], 2, "\t")
  end

  task :import_valve, [:file] => :environment do |t, args|
    import_prize_from_text(args[:file], 3, "\t")
  end

  task :import_ea_bejeweled, [:file] => :environment do |t, args|
    import_prize_from_text(args[:file], 4, "\t")
  end

  task :import_ea_fifa, [:file] => :environment do |t, args|
    import_prize_from_text(args[:file], 5, "\t")
  end

  task :import_ea_simcity, [:file] => :environment do |t, args|
    import_prize_from_text(args[:file], 6, "\t")
  end

  task :import_ea_pvz, [:file] => :environment do |t, args|
    import_prize_from_text(args[:file], 7, "\t")
  end

  task :import_skype, [:file] => :environment do |t, args|
    import_prize_from_text(args[:file], 10, ",")
  end

  task :import_donorschoose_750, [:file] => :environment do |t, args|
    Rails.logger.info "Importing teacher prize codes from: " + args[:file] + " for provider id 8"
    CSV.read(args[:file], { col_sep: ",", headers: true }).each do |row|
      if row['Gift Code'].present?
        TeacherPrize.create!(prize_provider_id: 8, code: row['Gift Code'])
      end
    end
  end

  task :import_donorschoose_250, [:file] => :environment do |t, args|
    Rails.logger.info "Importing teacher bonus prize codes from: " + args[:file] + " for provider id 9"
    CSV.read(args[:file], { col_sep: ",", headers: true }).each do |row|
      if row['Gift Code'].present?
        TeacherBonusPrize.create!(prize_provider_id: 9, code: row['Gift Code'])
      end
    end
  end

  task all: [:videos, :concepts, :games, :callouts, :scripts, :trophies, :prize_providers]
end
