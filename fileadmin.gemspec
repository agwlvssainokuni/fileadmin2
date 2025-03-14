# frozen_string_literal: true

require_relative "lib/file_admin/version"

Gem::Specification.new do |spec|
  spec.name = "fileadmin"
  spec.version = FileAdmin::VERSION
  spec.authors = ["agwlvssainokuni"]
  spec.email = ["agw.lvs.sainokuni@gmail.com"]

  spec.summary = "FileAdmin - ファイル管理"
  spec.description = "FileAdmin - ファイル管理"
  spec.homepage = "https://github.com/agwlvssainokuni/fileadmin2"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "syslog", "~> 0.2.0"
  spec.add_dependency "rubyzip", "~> 2.4.1"
  spec.add_dependency "activesupport", "~> 8.0.2"
  spec.add_dependency "activemodel", "~> 8.0.2"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
