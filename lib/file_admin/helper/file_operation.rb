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

require 'fileutils'
require 'pathname'
require 'zip'

module FileAdmin
  module Helper

    # コマンド実行機能
    module FileOperation

      # ファイルをディレクトリに移動する。
      def mv(file, to_dir, dry_run = false)
        logger.debug("processing: mv %s %s", file, to_dir)
        begin
          to_file = Pathname(to_dir).join(File.basename(file))
          FileUtils.mv(file, to_file, :noop => dry_run)
          return true
        rescue Exception => err
          logger.error("mv %s %s: NG, class=%s, message=%s",
                       file, to_dir, err.class, err.message)
          return false
        end
      end

      # ファイルを削除する。
      def rm(file, dry_run = false)
        logger.debug("processing: rm %s", file)
        begin
          FileUtils.rm(file, :noop => dry_run)
          return true
        rescue Exception => err
          logger.error("rm %s: NG, class=%s, message=%s",
                       file, err.class, err.message)
          return false
        end
      end

      # リストで指定されたファイルを対象としてアーカイブする (削除あり)。
      def zip_with_moving_files(arcfile, filelist, dry_run = false)
        return exec_zip(arcfile, filelist, true, dry_run)
      end

      # リストで指定されたファイルを対象としてアーカイブする (削除なし)。
      def zip_without_moving_files(arcfile, filelist, dry_run = false)
        return exec_zip(arcfile, filelist, false, dry_run)
      end

      # リストで指定されたファイル/ディレクトリを対象として
      # ZIPコマンドを実行する。
      def exec_zip(arcfile, filelist, move, dry_run = false)
        logger.debug("processing: zip %s %s",
                     arcfile, filelist * " ")
        return true if dry_run
        begin
          Zip::File.open(arcfile, Zip::File::CREATE) { |zipfile|
            filelist.each { |file| zipfile.add(file, file) }
          }
        rescue Exception => err
          logger.error("zip %s %s: NG, class=%s, message=%s",
                       arcfile, filelist * " ", err.class, err.message)
          return false
        end
        if move
          logger.debug("processing: rm %s", filelist * " ")
          begin
            FileUtils.rm(filelist, :noop => dry_run)
          rescue Exception => err
            logger.error("rm %s: NG, class=%s, message=%s",
                         filelist * " ", err.class, err.message)
            return false
          end
        end
        return true
      end

      # ファイルの所有者を変更する。
      def chown(owner, path, dry_run = false)
        logger.debug("processing: chown %s %s", owner, path)
        begin
          og = owner.split(":")
          u = og[0]
          g = og.length < 2 ? nil : og[1]
          FileUtils.chown(u, g, path, :noop => dry_run)
          return true
        rescue Exception => err
          logger.error("chown %s %s: NG, class=%s, message=%s",
                       owner, path, err.class, err.message)
          return false
        end
      end

    end
  end
end
