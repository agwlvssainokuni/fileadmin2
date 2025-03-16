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

require "active_model"
require "file_admin/helper/target_collector"

module FileAdmin

  class CollectByGeneration
    include ActiveModel::Validations
    include Helper::TargetCollector

    attr_accessor :pattern, :extra_cond, :comparator, :generation
    validates :pattern, presence: true
    validates_each :pattern do |record, attr, value|
      if value.present? && Array(value).select { |v| v.blank? }.present?
        record.errors.add(attr, "Can't be blank")
      end
    end
    validates :extra_cond, presence: true
    validates :comparator, presence: true
    validates :generation, presence: true

    def initialize
      @extra_cond = proc { true }
      @comparator = proc { |a, b| a <=> b }
      @generation = 0
    end

    def collect
      collect_target_by_generation(pattern, extra_cond, comparator, generation)
    end
  end

  class CollectByThreshold
    include ActiveModel::Validations
    include Helper::TargetCollector

    attr_accessor :pattern, :extra_cond, :comparator, :slicer, :threshold
    validates :pattern, presence: true
    validates_each :pattern do |record, attr, value|
      if value.present? && Array(value).select { |v| v.blank? }.present?
        record.errors.add(attr, "Can't be blank")
      end
    end
    validates :extra_cond, presence: true
    validates :comparator, presence: true
    validates :slicer, presence: true
    validates :threshold, presence: true

    def initialize
      @extra_cond = proc { true }
      @comparator = proc { |a, b| a <=> b }
      @slicer = proc { |a| a }
      @threshold = ""
    end

    def collect
      collect_target_by_threshold(pattern, extra_cond, comparator, slicer, threshold)
    end
  end

end
