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

require "file_admin/helper/target_collector"

RSpec.describe FileAdmin::Helper::TargetCollector do
  include FileAdmin::Helper::TargetCollector

  before(:all) do
    @list = [
      "testdir/dir1/file11.txt",
      "testdir/dir1/file12.txt",
      "testdir/dir2/file21.txt",
      "testdir/dir2/file22.txt",
      "testdir/dir3/file31.lst",
      "testdir/dir3/file32.lst"
    ]
  end

  before(:each) do
    @list.each { |file|
      %x{mkdir -p #{File.dirname(file)}}
      %x{touch #{file}}
    }
  end

  after(:each) do
    %x{rm -rf testdir}
  end

  describe "collect_target_by_generation" do
    subject { collect_target_by_generation(@pattern, @extra_cond, @comparator, @generation) }

    context "@pattern(文字列)を指定して絞込み" do
      before do
        @pattern = "testdir/*/*"
        @extra_cond = proc { true }
        @comparator = proc { |a, b| a <=> b }
        @generation = 0
      end
      it { is_expected.to match_array @list }
    end
    context "@pattern(配列)を指定して絞込み" do
      before do
        @pattern = [
          "testdir/dir1/*", "testdir/dir2/*", "testdir/dir3/*"
        ]
        @extra_cond = proc { true }
        @comparator = proc { |a, b| a <=> b }
        @generation = 0
      end
      it { is_expected.to match_array @list }
    end
    context "@patternと@extra_cond(正規表現)を指定して絞込み" do
      before do
        @pattern = "testdir/*/*"
        @extra_cond = proc { |path|
          path =~ /file(\d{2})\.txt\z/
        }
        @comparator = proc { |a, b| a <=> b }
        @generation = 0
      end
      it { is_expected.to match_array @list[0..3] }
    end
    context "@patternと@extra_cond(正規表現+追加条件)を指定して絞込み" do
      before do
        @pattern = "testdir/*/*"
        @extra_cond = proc { |path|
          path =~ /file(\d{2})\.txt\z/ && $1.to_i > 20
        }
        @comparator = proc { |a, b| a <=> b }
        @generation = 0
      end
      it { is_expected.to match_array @list[2..3] }
    end
    context "@pattern(文字列)と@generationを指定して絞込み" do
      before do
        @pattern = "testdir/*/*"
        @extra_cond = proc { true }
        @comparator = proc { |a, b| a <=> b }
        @generation = 1
      end
      it { is_expected.to match_array @list[0..4] }
    end
    context "@pattern(配列)と@generationを指定して絞込み" do
      before do
        @pattern = [
          "testdir/dir1/*", "testdir/dir2/*", "testdir/dir3/*"
        ]
        @extra_cond = proc { true }
        @comparator = proc { |a, b| a <=> b }
        @generation = 1
      end
      it { is_expected.to match_array [@list[0], @list[2], @list[4]] }
    end
  end

  describe "collect_target_by_threshold" do
    subject { collect_target_by_threshold(@pattern, @extra_cond, @comparator, @slicer, "30") }

    context "@pattern(文字列)を指定して絞込み" do
      before do
        @pattern = "testdir/*/*"
        @extra_cond = proc { true }
        @comparator = proc { |a, b| a <=> b }
        @slicer = proc { |path| path =~ /(.{2})\.txt\z/ ? $1 : nil }
      end
      it { is_expected.to match_array @list[0..3] }
    end
    context "@pattern(配列)を指定して絞込み" do
      before do
        @pattern = [
          "testdir/dir1/*", "testdir/dir2/*", "testdir/dir3/*"
        ]
        @extra_cond = proc { true }
        @comparator = proc { |a, b| a <=> b }
        @slicer = proc { |path| path =~ /(.{2})\.txt\z/ ? $1 : nil }
      end
      it { is_expected.to match_array @list[0..3] }
    end
    context "@patternと@extra_cond(正規表現)を指定して絞込み" do
      before do
        @pattern = "testdir/*/*"
        @extra_cond = proc { |path|
          path =~ /file(\d1)\.txt\z/
        }
        @comparator = proc { |a, b| a <=> b }
        @slicer = proc { |path| path =~ /(.{2})\.txt\z/ ? $1 : nil }
      end
      it { is_expected.to match_array [@list[0], @list[2]] }
    end
    context "@patternと@extra_cond(正規表現+追加条件)を指定して絞込み" do
      before do
        @pattern = "testdir/*/*"
        @extra_cond = proc { |path|
          path =~ /file(\d1)\.txt\z/ && $1.to_i > 20
        }
        @slicer = proc { |path| path =~ /(.{2})\.txt\z/ ? $1 : nil }
      end
      it { is_expected.to match_array [@list[2]] }
    end
  end
end
