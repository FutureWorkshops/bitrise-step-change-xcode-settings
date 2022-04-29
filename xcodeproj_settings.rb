require 'xcodeproj'

module XcodeProjSetting
  def self.change_setting(project_filepath, target_name, project_configuration, key, new_value, verbose)

    configuration = self.get_config_obj(project_filepath, target_name, project_configuration, verbose)
    if configuration.nil?
      puts "ERROR: Unable to find configuration '#{project_configuration}'!"
      exit -12
    end

    puts "*** Setting Xcode Project's #{key} to '#{new_value}' on target '#{target_name}' for configuration '#{project_configuration}'" if verbose == true

    configuration.build_settings[key] = new_value
    configuration.project.save
    
  end

  def self.print_setting(project_filepath, target_name, project_configuration, key)
    configuration = self.get_config_obj(project_filepath, target_name, project_configuration, false)
    if configuration.nil?
      puts "ERROR: Unable to find configuration '#{project_configuration}'!"
      exit -12
    end

    puts configuration.build_settings[key]

  end

  private
  def self.get_config_obj(project_filepath, target_name, project_configuration, verbose)
    project_directory=File.dirname project_filepath
    unless File.directory?(project_directory)
      puts "ERROR: The project folder '#{project_directory}' doesn't exist."
      exit -12
    end

    unless File.exists?(project_filepath)
      puts "ERROR: The project file '#{project_filepath}' doesn't exist."
      exit -12
    end

    puts "*** Parsing project at '#{project_filepath}'" if verbose == true
    project = Xcodeproj::Project.open(project_filepath)
    target = project.targets.find { |t| t.name == target_name }
    if target.nil?
      puts "ERROR: Unable to find target '#{target_name}'!"
      exit -12
    end

    target.build_configurations.find { |c| c.name == project_configuration }

  end

end
