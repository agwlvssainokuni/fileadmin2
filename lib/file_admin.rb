# frozen_string_literal: true
#
#  Copyright 2025 agwlvssainokuni
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require 'optparse'
require "file_admin/dsl"

def file_admin

  opt_time = Time.now
  opt_validate = false
  opt_dry_run = false

  opt = OptionParser.new
  opt.on("--time TIME", "基準日時指定") { |p| opt_time = Time.parse(p) }
  opt.on("--[no-]validate", "設定チェック") { |p| opt_validate = p }
  opt.on("--[no-]dry-run", "ドライラン") { |p| opt_dry_run = p }
  opt.on("--[no-]syslog", "SYSLOG出力フラグ") { |p| FileAdmin::Helper::Logger.syslog_enabled = p }
  opt.on("--[no-]console", "コンソール出力フラグ") { |p| FileAdmin::Helper::Logger.console_enabled = p }
  opt.parse!(ARGV)

  ARGV.each do |file|
    load file
  end

  ok = true
  FileAdmin::DSL.configuration.each do |conf|
    if opt_validate
      ok = false unless conf.valid?
      conf.errors.each do |error|
        conf.logger.error(error.full_message)
      end
    else
      ok = false unless conf.process(opt_time, opt_dry_run)
    end
  end

  ok
end

if $0 == __FILE__
  ok = file_admin
  exit(ok ? 0 : 1)
end
