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

  # 集約アーカイブ作成機能
  class ArchiveManyToOne
    include ActiveModel::Validations
    include FileAdmin::Helper::FileOperation
    include FileAdmin::Helper::TargetCollector

    attr_reader :logger

    attr_accessor :basedir, :arcname, :to_dir, :owner
    validates :basedir, presence: true
    validates :arcname, presence: true

    attr_accessor :collector
    validates :collector, presence: true
    validates_each :collector do |record, attr, value|
      if value.present? && value.invalid?
        value.errors.each { |error| record.errors.add(attr, error) }
      end
    end

    def initialize(label)
      @logger = FileAdmin::Helper::Logger.new("MANY2ONE[#{label}]")
    end

    # 複合アーカイブ作成
    def process(time = Time.now, dry_run = false)
      logger.debug("start")

      Dir.chdir(basedir) {

        files = collector.collect.select { |f| File.file?(f) }
        if files.empty?
          logger.debug("no files, skipped")
          return true
        end

        arcfile = File.join(
          to_dir.present? ? to_dir : ".",
          time.strftime(arcname)
        )

        return false unless zip_with_moving_files(arcfile, files, dry_run)
        logger.info("zip %s %s: OK", arcfile, files * " ") unless dry_run
        if owner.present?
          return false unless chown(owner, arcfile, dry_run)
        end
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
