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

FileAdmin.configure do

  basedir = File.dirname(File.absolute_path(__FILE__))

  archive_one_to_one("一対一アーカイブ") do |c|
    c.basedir = "#{basedir}/0file"
    c.arcname = proc { |a| File.basename(a, ".txt") + ".zip" }
    c.to_dir = "#{basedir}/1arch"
    collect_by_generation do |t|
      t.pattern = "foreach_*.txt"
      t.extra_cond = proc { |a| /_(\d{14})\.txt\z/ =~ a }
    end
  end

  archive_many_to_one("集約アーカイブ") do |c|
    c.basedir = "#{basedir}/0file"
    c.arcname = "aggregate_%Y%m%d%H%M%S.zip"
    c.to_dir = "#{basedir}/1arch"
    collect_by_generation do |t|
      t.pattern = "aggregate_*.txt"
    end
  end

  backup_file("退避テスト") do |c|
    c.basedir = "#{basedir}/1arch"
    c.to_dir = "#{basedir}/2back"
    collect_by_threshold do |t|
      t.pattern = ["foreach_*.zip", "aggregate_*.zip"]
      t.slicer = proc { |a| /_(\d{14})\.zip\z/ =~ a ? $1 : nil }
      t.threshold = proc { |time| (time - 1.days).strftime("%Y%m%d%H%M%S") }
    end
  end

  cleanup_file("削除テスト") do |c|
    c.basedir = "#{basedir}/2back"
    collect_by_threshold do |t|
      t.pattern = ["foreach_*.zip", "aggregate_*.zip"]
      t.slicer = proc { |a| /_(\d{14})\.zip\z/ =~ a ? $1 : nil }
      t.threshold = proc { |time| (time - 2.days).strftime("%Y%m%d%H%M%S") }
    end
  end

end
