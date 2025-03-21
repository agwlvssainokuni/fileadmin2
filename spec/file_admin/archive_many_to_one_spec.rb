# -*- coding: utf-8 -*-
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

require "file_admin/archive_many_to_one"
require "file_admin/collector"
require_relative "spec_helper"

FileAdmin::Helper::Logger.console_enabled = false
FileAdmin::Helper::Logger.syslog_enabled = false

RSpec.describe FileAdmin::ArchiveManyToOne do

  subject { create_subject(FileAdmin::ArchiveManyToOne, FileAdmin::CollectByGeneration, "アーカイブ(N:1)試験", conf, conf_collect) }

  let(:base_conf) { {
    "basedir" => "#{Dir.pwd}/testdir/src",
    "arcname" => "arcfile_%Y%m%d%H%M%S.zip",
    "to_dir" => "#{Dir.pwd}/testdir/dest",
    "owner" => "#{%x{whoami}.chop}:#{%x{groups $(whoami) | awk '{print $1;}'}.chop}"
  } }
  let(:base_conf_collect) { {
    "pattern" => ["dir1/*", "dir2/*"],
    "extra_cond" => proc { |a| /file(\d{2})\.txt\z/ =~ a && $1.to_i > 10 },
    "comparator" => proc { |a, b| a <=> b },
    "generation" => 0,
  } }

  describe "valid?" do

    context "全指定 (patternは配列)" do
      let(:conf) { base_conf }
      let(:conf_collect) { base_conf_collect }
      it { expect(subject).to be_valid }
    end

    context "全指定 (patternは文字列)" do
      let(:conf) { base_conf }
      let(:conf_collect) { base_conf_collect.merge("pattern" => "dir1/*") }
      it { expect(subject).to be_valid }
    end

    context "basedirなし" do
      let(:conf) { base_conf.merge("basedir" => nil) }
      let(:conf_collect) { base_conf_collect }
      it { expect(subject).not_to be_valid }
    end

    context "arcnameなし" do
      let(:conf) { base_conf.merge("arcname" => nil) }
      let(:conf_collect) { base_conf_collect }
      it { expect(subject).not_to be_valid }
    end

    context "to_dirなし" do
      let(:conf) { base_conf.merge("to_dir" => nil) }
      let(:conf_collect) { base_conf_collect }
      it { expect(subject).to be_valid }
    end

    context "ownerなし" do
      let(:conf) { base_conf.merge("owner" => nil) }
      let(:conf_collect) { base_conf_collect }
      it { expect(subject).to be_valid }
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

    context "generationなし" do
      let(:conf) { base_conf }
      let(:conf_collect) { base_conf_collect.merge("generation" => nil) }
      it { expect(subject).not_to be_valid }
    end
  end

  describe "process" do
    let(:time) { Time.now }
    let(:strftime) { time.strftime("%Y%m%d%H%M%S") }
    let(:arcfile) { "arcfile_#{strftime}.zip" }
    let(:arcdir) { "testdir/dest" }
    let(:files_not_in_archive) {
      file_list.reject { |f| files_in_archive.include?(f) }
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

      shared_examples_for "アーカイブ(N:1)して正常終了" do
        before do
          @retval = subject.process(time, dry_run)
        end
        context "通常 (retval,arcfile,inarc,unzip,not_inarc,unzip)" do
          let(:dry_run) { false }
          it { expect(@retval).to be_truthy }
          it { expect(Pathname("#{arcdir}/#{arcfile}")).to be_file }
          it {
            files_in_archive.each { |f|
              expect(Pathname("testdir/src/#{f}")).not_to exist
            }
          }
          it {
            files_in_archive.each { |f|
              %x{unzip -l #{arcdir}/#{arcfile} #{f} 2>&1}
              expect($?).to eq 0
            }
          }
          it {
            files_not_in_archive.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
          it {
            files_not_in_archive.each { |f|
              %x{unzip -l #{arcdir}/#{arcfile} #{f} 2>&1}
              expect($?).not_to eq 0
            }
          }
        end
        context "ドライ (retval,arcfile,file_list)" do
          let(:dry_run) { true }
          it { expect(@retval).to be_truthy }
          it { expect(Pathname("#{arcdir}/#{arcfile}")).not_to exist }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
        end
      end

      describe "単一ファイル" do
        it_behaves_like "アーカイブ(N:1)して正常終了"
        let(:file_list) { ["dir1/file11.txt"] }
        let(:files_in_archive) { file_list }
        let(:conf) { base_conf }
        let(:conf_collect) { base_conf_collect }
      end

      describe "複数ファイル (絞込みなし)" do
        it_behaves_like "アーカイブ(N:1)して正常終了"
        let(:file_list) {
          [
            "dir1/file11.txt", "dir1/file12.txt",
            "dir2/file21.txt", "dir2/file22.txt"
          ]
        }
        let(:files_in_archive) { file_list }
        let(:conf) { base_conf }
        let(:conf_collect) { base_conf_collect }
      end

      describe "複数ファイル (to_dir指定なし)" do
        it_behaves_like "アーカイブ(N:1)して正常終了"
        let(:file_list) {
          [
            "dir1/file11.txt", "dir1/file12.txt",
            "dir2/file21.txt", "dir2/file22.txt"
          ]
        }
        let(:files_in_archive) { file_list }
        let(:conf) { base_conf.merge("to_dir" => nil) }
        let(:conf_collect) { base_conf_collect }
        let(:arcdir) { "testdir/src" }
      end

      describe "複数ファイル (owner指定なし)" do
        it_behaves_like "アーカイブ(N:1)して正常終了"
        let(:file_list) {
          [
            "dir1/file11.txt", "dir1/file12.txt",
            "dir2/file21.txt", "dir2/file22.txt"
          ]
        }
        let(:files_in_archive) { file_list }
        let(:conf) { base_conf.merge("owner" => nil) }
        let(:conf_collect) { base_conf_collect }
      end

      describe "複数ファイル (patternで絞込み)" do
        it_behaves_like "アーカイブ(N:1)して正常終了"
        let(:file_list) {
          [
            "dir1/file11.txt", "dir1/file12.txt",
            "dir2/file21.txt", "dir2/file22.txt"
          ]
        }
        let(:files_in_archive) { [file_list[0], file_list[1]] }
        let(:conf) { base_conf }
        let(:conf_collect) { base_conf_collect.merge("pattern" => "dir1/*") }
      end

      describe "複数ファイル (extra_cond(正規表現)で絞込み)" do
        it_behaves_like "アーカイブ(N:1)して正常終了"
        let(:file_list) {
          [
            "dir1/file11.txt", "dir1/file12.txt",
            "dir2/file21.txt", "dir2/file22.txt"
          ]
        }
        let(:files_in_archive) { [file_list[0], file_list[2]] }
        let(:conf) { base_conf }
        let(:conf_collect) {
          base_conf_collect.merge("extra_cond" => proc { |a| /file(\d1)\.txt\z/ =~ a })
        }
      end

      describe "複数ファイル (extra_cond(正規表現+追加条件)で絞込み)" do
        it_behaves_like "アーカイブ(N:1)して正常終了"
        let(:file_list) {
          [
            "dir1/file11.txt", "dir1/file12.txt",
            "dir2/file21.txt", "dir2/file22.txt"
          ]
        }
        let(:files_in_archive) { [file_list[2], file_list[3]] }
        let(:conf) { base_conf }
        let(:conf_collect) {
          base_conf_collect.merge("extra_cond" => proc { |a| /file(\d{2})\.txt\z/ =~ a && $1.to_i > 20 })
        }
      end

      describe "複数ファイル (generationで絞込み)" do
        it_behaves_like "アーカイブ(N:1)して正常終了"
        let(:file_list) {
          [
            "dir1/file11.txt", "dir1/file12.txt",
            "dir2/file21.txt", "dir2/file22.txt"
          ]
        }
        let(:files_in_archive) { [file_list[0], file_list[1]] }
        let(:conf) { base_conf }
        let(:conf_collect) {
          base_conf_collect.merge("pattern" => "*/*", "generation" => 2)
        }
      end
    end

    describe "境界系" do

      shared_examples_for "アーカイブ(N:1)しないで正常終了" do
        before do
          @retval = subject.process(time, dry_run)
        end
        context "通常 (retval,arcfile,file_list)" do
          let(:dry_run) { false }
          it { expect(@retval).to be_truthy }
          it { expect(Pathname("#{arcdir}/#{arcfile}")).not_to exist }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
        end
        context "ドライ (retval,arcfile,file_list)" do
          let(:dry_run) { true }
          it { expect(@retval).to be_truthy }
          it { expect(Pathname("#{arcdir}/#{arcfile}")).not_to exist }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
        end
      end

      describe "pattern絞込みでディレクトリのみ" do
        it_behaves_like "アーカイブ(N:1)しないで正常終了"
        let(:file_list) {
          [
            "dir1/file11.txt", "dir1/file12.txt",
            "dir2/file21.txt", "dir2/file22.txt"
          ]
        }
        let(:conf) { base_conf }
        let(:conf_collect) {
          base_conf_collect.merge("pattern" => "*", "extra_cond" => proc { true })
        }
      end

      describe "pattern絞込みで0件" do
        it_behaves_like "アーカイブ(N:1)しないで正常終了"
        let(:file_list) {
          [
            "dir1/file11.txt", "dir1/file12.txt",
            "dir2/file21.txt", "dir2/file22.txt"
          ]
        }
        let(:conf) { base_conf }
        let(:conf_collect) {
          base_conf_collect.merge("pattern" => "nodir/*", "extra_cond" => proc { true })
        }
      end

      describe "extra_cond(正規表現)絞込みで0件" do
        it_behaves_like "アーカイブ(N:1)しないで正常終了"
        let(:file_list) {
          [
            "dir1/file11.txt", "dir1/file12.txt",
            "dir2/file21.txt", "dir2/file22.txt"
          ]
        }
        let(:conf) { base_conf }
        let(:conf_collect) {
          base_conf_collect.merge("extra_cond" => proc { |a| /(\d{2})\.not\z/ =~ a })
        }
      end

      describe "extra_cond(正規表現+追加条件)絞込みで0件" do
        it_behaves_like "アーカイブ(N:1)しないで正常終了"
        let(:file_list) {
          [
            "dir1/file11.txt", "dir1/file12.txt",
            "dir2/file21.txt", "dir2/file22.txt"
          ]
        }
        let(:conf) { base_conf }
        let(:conf_collect) {
          base_conf_collect.merge("extra_cond" => proc { |a| /file(\d{2})\.txt\z/ =~ a && $1.to_i < 0 })
        }
      end
    end

    describe "異常系" do

      describe "basedir不正" do
        let(:file_list) {
          [
            "dir1/file11.txt", "dir1/file12.txt",
            "dir2/file21.txt", "dir2/file22.txt"
          ]
        }
        let(:conf) { base_conf.merge("basedir" => "testdir/nosrc") }
        let(:conf_collect) { base_conf_collect }
        before do
          @retval = subject.process(time, dry_run)
        end

        context "通常 (retval,arcfile,file_list)" do
          let(:dry_run) { false }
          it { expect(@retval).to be_falsey }
          it { expect(Pathname("#{arcdir}/#{arcfile}")).not_to exist }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
        end
        context "ドライ (retval,arcfile,file_list); dryでもchdirする" do
          let(:dry_run) { true }
          # dry_runでもchdirするのでfalse
          it { expect(@retval).to be_falsey }
          it { expect(Pathname("#{arcdir}/#{arcfile}")).not_to exist }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
        end
      end

      describe "zip作成失敗 (書込権限なし)" do
        let(:file_list) {
          [
            "dir1/file11.txt", "dir1/file12.txt",
            "dir2/file21.txt", "dir2/file22.txt"
          ]
        }
        let(:conf) { base_conf }
        let(:conf_collect) { base_conf_collect }
        before do
          %x{chmod -w testdir/dest}
          @retval = subject.process(time, dry_run)
        end

        context "通常 (retval,arcfile,file_list)" do
          let(:dry_run) { false }
          it { expect(@retval).to be_falsey }
          it { expect(Pathname("#{arcdir}/#{arcfile}")).not_to exist }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
        end
        context "ドライ (retval,arcfile,file_list)" do
          let(:dry_run) { true }
          it { expect(@retval).to be_truthy }
          it { expect(Pathname("#{arcdir}/#{arcfile}")).not_to exist }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
        end
      end

      describe "owner失敗 (存在しないユーザ)" do
        let(:file_list) {
          [
            "dir1/file11.txt", "dir1/file12.txt",
            "dir2/file21.txt", "dir2/file22.txt"
          ]
        }
        let(:conf) { base_conf.merge("owner" => "nouser") }
        let(:conf_collect) { base_conf_collect }
        before do
          @retval = subject.process(time, dry_run)
        end

        context "通常 (retval,arcfile,file_list); zipは作られる" do
          let(:dry_run) { false }
          it { expect(@retval).to be_falsey }
          # zipは作られる
          it { expect(Pathname("#{arcdir}/#{arcfile}")).to be_file }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).not_to exist
            }
          }
        end
        context "ドライ (retval,arcfile,file_list)" do
          let(:dry_run) { true }
          it { expect(@retval).to be_truthy }
          it { expect(Pathname("#{arcdir}/#{arcfile}")).not_to exist }
          it {
            file_list.each { |f|
              expect(Pathname("testdir/src/#{f}")).to be_file
            }
          }
        end
      end

    end
  end

end
