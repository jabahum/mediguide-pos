#!/usr/bin/env ruby

require "xcodeproj"

project_path = File.expand_path("../ios/Runner.xcodeproj", __dir__)
project = Xcodeproj::Project.open(project_path)
runner = project.targets.find { |target| target.name == "Runner" }
tests = project.targets.find { |target| target.name == "RunnerTests" }
abort "Runner target was not found" unless runner

flavors = {
  "development" => {
    bundle_id: "com.omarsoft.mediguide.dev",
    app_name: "MediGuide Dev",
  },
  "staging" => {
    bundle_id: "com.omarsoft.mediguide.staging",
    app_name: "MediGuide Staging",
  },
  "production" => {
    bundle_id: "com.omarsoft.mediguide",
    app_name: "MediGuide",
  },
}.freeze

configuration_types = {
  "Debug" => :debug,
  "Profile" => :release,
  "Release" => :release,
}.freeze

def duplicate_configuration(owner, source_name, destination_name, type)
  source = owner.build_configurations.find { |configuration| configuration.name == source_name }
  abort "Missing source configuration #{source_name}" unless source

  destination = owner.build_configurations.find do |configuration|
    configuration.name == destination_name
  end
  destination ||= owner.add_build_configuration(destination_name, type)
  destination.build_settings.clear
  destination.build_settings.update(source.build_settings)
  destination.base_configuration_reference = source.base_configuration_reference
  destination
end

flavors.each do |flavor, values|
  configuration_types.each do |mode, type|
    name = "#{mode}-#{flavor}"
    duplicate_configuration(project, mode, name, type)

    runner_configuration = duplicate_configuration(runner, mode, name, type)
    config_path = "Flutter/#{name}.xcconfig"
    config_reference = project.files.find { |file| file.path == config_path }
    if config_reference.nil?
      stale_reference = project.files.find { |file| file.path == "#{name}.xcconfig" }
      stale_reference&.remove_from_project
      config_reference = project.main_group.new_file(config_path)
    end
    runner_configuration.base_configuration_reference = config_reference
    runner_configuration.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = values[:bundle_id]
    runner_configuration.build_settings["MEDIGUIDE_APP_NAME"] = values[:app_name]

    next unless tests

    tests_configuration = duplicate_configuration(tests, mode, name, type)
    tests_configuration.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] =
      "#{values[:bundle_id]}.RunnerTests"
  end

  scheme = Xcodeproj::XCScheme.new
  if tests
    scheme.configure_with_targets(runner, tests)
  else
    scheme.configure_with_targets(runner, nil)
  end
  scheme.test_action.build_configuration = "Debug-#{flavor}"
  scheme.launch_action.build_configuration = "Debug-#{flavor}"
  scheme.analyze_action.build_configuration = "Debug-#{flavor}"
  scheme.profile_action.build_configuration = "Profile-#{flavor}"
  scheme.archive_action.build_configuration = "Release-#{flavor}"
  scheme.save_as(project_path, flavor, true)
end

project.save
puts "Configured iOS flavors: #{flavors.keys.join(', ')}"
