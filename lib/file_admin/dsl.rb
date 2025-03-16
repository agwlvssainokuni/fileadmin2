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

require "file_admin/archive_many_to_one"
require "file_admin/archive_one_to_one"
require "file_admin/collector"

module FileAdmin
  class DSL

    def configuration
      @configuration ||= []
    end

    def archive_many_to_one(label)
      obj = FileAdmin::ArchiveManyToOne.new(label)
      configuration << obj
      yield obj
    end

    def archive_one_to_one(label)
      obj = FileAdmin::ArchiveOneToOne.new(label)
      configuration << obj
      yield obj
    end

    def collect_by_generation
      obj = FileAdmin::CollectByGeneration.new
      configuration.last.collector = obj
      yield obj
    end

    def collect_by_threshold
      obj = FileAdmin::CollectByThreshold.new
      configuration.last.collector = obj
      yield obj
    end
  end
end
