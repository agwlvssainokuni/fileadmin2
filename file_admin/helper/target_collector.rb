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

module FileAdmin
  module Helper
    # 対象抽出
    module TargetCollector

      # 保持世代数を指定して対象を抽出する。
      def collect_target_by_generation(pattern, extra_cond, comparator, generation)
        Array(pattern).flat_map { |pat|
          collect_target_common(pat, extra_cond, comparator)[0..-(generation + 1)]
        }
      end

      # 閾値を指定して対象を抽出する。
      def collect_target_by_threshold(pattern, extra_cond, comparator, slicer, threshold)
        Array(pattern).flat_map { |pat|
          collect_target_common(pat, extra_cond, comparator).select { |path|
            slicer.call(path)&.< threshold
          }
        }
      end

      private

      # DIRパターンを指定して対象を抽出する。
      def collect_target_common(pat, extra_cond, comparator)
        Dir.glob(pat).select(&extra_cond).sort(&comparator)
      end

    end
  end
end
