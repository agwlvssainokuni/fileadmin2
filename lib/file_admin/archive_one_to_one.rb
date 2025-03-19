# frozen_string_literal: true
#
#  Copyright 2012,2025 agwlvssainokuni
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

require "active_support"
require "active_model"
require "file_admin/helper/logger"
require "file_admin/helper/file_operation"
require "file_admin/helper/target_collector"

module FileAdmin

  # 一対一アーカイブ作成機能
  class ArchiveOneToOne
    include ActiveModel::Validations
    include FileAdmin::Helper::FileOperation
    include FileAdmin::Helper::TargetCollector

    attr_reader :logger

    attr_accessor :basedir, :arcname, :to_dir, :owner
    validates :basedir, presence: true
    validates :arcname, presence: true

    attr_accessor :collector
    validates :collector, presence: true
    validate do |record|
      if record.collector.present? && record.collector.invalid?
        record.errors.merge!(record.collector.errors)
      end
    end

    def initialize(label)
      @logger = FileAdmin::Helper::Logger.new("ONE2ONE[#{label}]")
    end

    # 一対一アーカイブ作成
    def process(time = Time.now, dry_run = false)
      logger.debug("start")

      Dir.chdir(basedir) {

        files = collector.collect(time).select { |f| File.file?(f) }
        if files.empty?
          logger.debug("no files, skipped")
          return true
        end

        files.each { |f|

          arcfile = File.join(
            to_dir.present? ? to_dir : File.dirname(f),
            arcname.call(File.basename(f))
          )

          return false unless zip_with_moving_files(arcfile, Array(f), dry_run)
          logger.info("zip %s %s: OK", arcfile, f)
          if owner.present?
            return false unless chown(owner, arcfile, dry_run)
          end
        }
      }

      logger.debug("end normally")
      return true
    rescue Exception => err
      logger.error("chdir %s: NG; class=%s, message=%s",
                   basedir, err.class, err.message)
      return false
    end

  end
end
