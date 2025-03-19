# -*- coding: utf-8 -*-
#
#  Copyright 2012,2014 agwlvssainokuni
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

require "active_support/core_ext/integer/time"
require "file_admin/backup_file"
require "file_admin/collector"
require_relative "spec_helper"

FileAdmin::Helper::Logger.console_enabled = false
FileAdmin::Helper::Logger.syslog_enabled = false

RSpec.describe FileAdmin::BackupFile do

  subject { create_subject(FileAdmin::BackupFile, FileAdmin::CollectByThreshold, "ファイル退避試験", conf, conf_collect) }

  let(:base_conf) { {
    "basedir" => "#{Dir.pwd}/testdir/src",
    "to_dir" => "#{Dir.pwd}/testdir/dest"
  } }
  let(:base_conf_collect) { {
    "pattern" => ["dir1/*", "dir2/*"],
    "extra_cond" => proc { |a| /file[12]_(\d{8})\.txt\z/ =~ a && $1 > "00000000" },
    "comparator" => proc { |a, b| a <=> b },
    "slicer" => proc { |a| /_(\d{8})\.txt\z/ =~ a ? $1 : nil },
    "threshold" => proc { |time| (time - 2.days).strftime("%Y%m%d") }
  } }

  describe "valid?" do

    context "全指定 (patternは配列)" do
      let(:conf) { base_conf }
      let(:conf_collect) { base_conf_collect }
      it { expect(subject).to be_valid }
    end

    context "全指定 (patternは文字列)" do
      let(:conf) { base_conf }
      let(:conf_collect) { base_conf_collect.merge("pattern" => "dir1/file_") }
      it { expect(subject).to be_valid }
    end

    context "basedirなし" do
      let(:conf) { base_conf.merge("basedir" => nil) }
      let(:conf_collect) { base_conf_collect }
      it { expect(subject).not_to be_valid }
    end

    context "to_dirなし" do
      let(:conf) { base_conf.merge("to_dir" => nil) }
      let(:conf_collect) { base_conf_collect }
      it { expect(subject).not_to be_valid }
    end

    context "patternなし" do
      let(:conf) { base_conf }
      let(:conf_collect) { base_conf_collect.merge("pattern" => nil) }
      it { expect(subject).not_to be_valid }
    end

    context "patternが空配列" do
      let(:conf) { base_conf }
      let(:conf_collect) { base_conf_collect.merge("pattern" => []) }
      it { expect(subject).not_to be_valid }
    end

    context "patternが空文字の配列" do
      let(:conf) { base_conf }
      let(:conf_collect) { base_conf_collect.merge("pattern" => [""]) }
      it { expect(subject).not_to be_valid }
    end

    context "extra_condなし" do
      let(:conf) { base_conf }
      let(:conf_collect) { base_conf_collect.merge("extra_cond" => nil) }
      it { expect(subject).not_to be_valid }
    end

    context "comparatorなし" do
      let(:conf) { base_conf }
      let(:conf_collect) { base_conf_collect.merge("comparator" => nil) }
      it { expect(subject).not_to be_valid }
    end

    context "slicerなし" do
      let(:conf) { base_conf }
      let(:conf_collect) { base_conf_collect.merge("slicer" => nil) }
      it { expect(subject).not_to be_valid }
    end

    context "thresholdなし" do
      let(:conf) { base_conf }
      let(:conf_collect) { base_conf_collect.merge("threshold" => nil) }
      it { expect(subject).not_to be_valid }
    end
  end

  describe "process" do
    let(:time) { Time.now }
    let(:timestamp) {
      (0..5).collect { |i| (time - i.days).strftime("%Y%m%d") }
    }
    let(:file_list_1) { timestamp.collect { |dt| "dir1/file1_#{dt}.txt" } }
    let(:file_list_2) { timestamp.collect { |dt| "dir2/file2_#{dt}.txt" } }
    let(:file_list) { file_list_1 + file_list_2 }
    let(:files_not_in_process) {
      file_list.reject { |f| files_in_process.include?(f) }
    }

    before(:each) do
      %x{mkdir -p testdir/src}
      %x{mkdir -p testdir/dest}
      file_list.each { |f|
        %x{mkdir -p testdir/src/#{File.dirname(f)}}
        %x{touch testdir/src/#{f}}
      }
    end
    after(:each) do
      %x{chmod -R +w testdir}
      %x{rm -rf testdir}
    end

    describe "正常系" do

      shared_examples_for "退避して正常終了" do
        before do
          @retval = subject.process(time, dry_run)
        end
        context "通常 (retval,src(proc,not),dest(proc,not))" do
          let(:dry_run) { false }
          it { expect(@retval).to be_truthy }
          it {
            files_in_process.each { |f|
              expect(Pathname("testdir/src/#{f}")).not_to exist
            }
          }
          it {
            files_not_in_process.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
          it {
            files_in_process.each { |f|
              bname = File.basename(f)
              expect(Pathname("testdir/dest/#{bname}")).to be_file
            }
          }
          it {
            files_not_in_process.each { |f|
              bname = File.basename(f)
              expect(Pathname("testdir/dest/#{bname}")).not_to exist
            }
          }
        end
        context "ドライ (retval,src,dest)" do
          let(:dry_run) { true }
          it { expect(@retval).to be_truthy }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
          it {
            file_list.each { |f|
              bname = File.basename(f)
              expect(Pathname("testdir/dest/#{bname}")).not_to exist
            }
          }
        end
      end

      describe "絞込みなし" do
        it_behaves_like "退避して正常終了"
        let(:files_in_process) {
          file_list_1[3..-1] + file_list_2[3..-1]
        }
        let(:conf) { base_conf }
        let(:conf_collect) { base_conf_collect }
      end

      describe "patternで絞込み" do
        it_behaves_like "退避して正常終了"
        let(:files_in_process) {
          file_list_1[3..-1]
        }
        let(:conf) { base_conf }
        let(:conf_collect) { base_conf_collect.merge("pattern" => "dir1/*") }
      end

      describe "extra_cond(正規表現)で絞込み" do
        it_behaves_like "退避して正常終了"
        let(:files_in_process) {
          file_list_1[3..-1]
        }
        let(:conf) { base_conf }
        let(:conf_collect) {
          base_conf_collect.merge("extra_cond" => proc { |a| /file1_(\d{8})\.txt\z/ =~ a })
        }
      end

      describe "extra_cond(正規表現+追加条件)で絞込み" do
        it_behaves_like "退避して正常終了"
        let(:files_in_process) {
          file_list_1[3..-2] + file_list_2[3..-2]
        }
        let(:conf) { base_conf }
        let(:conf_collect) {
          dt = (time - 5.days).strftime("%Y%m%d")
          base_conf_collect.merge("extra_cond" => proc { |a| /(\d{8})\.txt\z/ =~ a && $1 > dt })
        }
      end
    end

    describe "境界系" do

      shared_examples_for "退避しないで正常終了" do
        before do
          @retval = subject.process(time, dry_run)
        end
        context "通常 (retval,src,dest)" do
          let(:dry_run) { false }
          it { expect(@retval).to be_truthy }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
          it {
            file_list.each { |f|
              bname = File.basename(f)
              expect(Pathname("testdir/dest/#{bname}")).not_to exist
            }
          }
        end
        context "ドライ (retval,src,dest)" do
          let(:dry_run) { true }
          it { expect(@retval).to be_truthy }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
          it {
            file_list.each { |f|
              bname = File.basename(f)
              expect(Pathname("testdir/dest/#{bname}")).not_to exist
            }
          }
        end
      end

      describe "pattern絞込みでディレクトリのみ" do
        it_behaves_like "退避しないで正常終了"
        let(:conf) { base_conf }
        let(:conf_collect) {
          base_conf_collect.merge("pattern" => ["dir1", "dir2"])
        }
      end

      describe "pattern絞込みで0件" do
        it_behaves_like "退避しないで正常終了"
        let(:conf) { base_conf }
        let(:conf_collect) {
          base_conf_collect.merge("pattern" => ["dir1/file2_*", "dir2/file1_*"])
        }
      end

      describe "extra_cond(正規表現)絞込みで0件" do
        it_behaves_like "退避しないで正常終了"
        let(:conf) { base_conf }
        let(:conf_collect) {
          base_conf_collect.merge("extra_cond" => proc { |a| /file[34]_(\d{8})\.txt\z/ =~ a })
        }
      end

      describe "extra_cond(正規表現+追加条件)絞込みで0件" do
        it_behaves_like "退避しないで正常終了"
        let(:conf) { base_conf }
        let(:conf_collect) {
          base_conf_collect.merge("extra_cond" => proc { |a| /_(\d{8})\.txt\z/ =~ a && $1 > "9" })
        }
      end

      describe "thresholdが5日前" do
        it_behaves_like "退避しないで正常終了"
        let(:conf) { base_conf }
        let(:conf_collect) {
          base_conf_collect.merge("threshold" => proc { |time| (time - 5.days).strftime("%Y%m%d") })
        }
      end
    end

    describe "異常系" do

      describe "basedir不正" do
        let(:conf) { base_conf.merge("basedir" => "testdir/nosrc") }
        let(:conf_collect) { base_conf_collect }
        before do
          @retval = subject.process(time, dry_run)
        end

        context "通常 (retval,src,dest)" do
          let(:dry_run) { false }
          it { expect(@retval).to be_falsey }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
          it {
            file_list.each { |f|
              bname = File.basename(f)
              expect(Pathname("testdir/dest/#{bname}")).not_to exist
            }
          }
        end
        context "ドライ (retval,src,dest); dryでもchdirする" do
          let(:dry_run) { true }
          # dry_runでもchdirするのでfalse
          it { expect(@retval).to be_falsey }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
          it {
            file_list.each { |f|
              bname = File.basename(f)
              expect(Pathname("testdir/dest/#{bname}")).not_to exist
            }
          }
        end
      end

      describe "移動失敗 (書込権限なし)" do
        let(:conf) { base_conf }
        let(:conf_collect) { base_conf_collect }
        before do
          %x{chmod -w testdir/src/dir1}
          %x{chmod -w testdir/src/dir2}
          @retval = subject.process(time, dry_run)
        end

        context "通常 (retval,src,dest)" do
          let(:dry_run) { false }
          it { expect(@retval).to be_falsey }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
          it {
            file_list.each { |f|
              bname = File.basename(f)
              expect(Pathname("testdir/dest/#{bname}")).not_to exist
            }
          }
        end
        context "ドライ (retval,src,dest)" do
          let(:dry_run) { true }
          it { expect(@retval).to be_truthy }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
          it {
            file_list.each { |f|
              bname = File.basename(f)
              expect(Pathname("testdir/dest/#{bname}")).not_to exist
            }
          }
        end
      end

    end
  end

end
