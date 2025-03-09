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

require 'syslog'
require 'active_support/core_ext/class/attribute'

module FileAdmin
  module Helper

    # ログ出力機能
    class Logger
      # コンソールへの出力
      self.class_attribute :console_enabled, default: false
      # SYSLOGへの出力
      self.class_attribute :syslog_enabled, default: true

      # 初期化
      def initialize(l = "")
        @label = (l.empty? ? l : l + " ")
      end

      # デバッグログ (コンソール)
      def debug(msg, *arg)
        console("DEBUG", msg, *arg)
      end

      # 通知ログ (コンソール、SYSLOG)
      def info(msg, *arg)
        console("INFO", msg, *arg)
        syslog(Syslog::Constants::LOG_INFO, "INFO", msg, *arg)
      end

      # エラーログ (コンソール、SYSLOG)
      def error(msg, *arg)
        console("ERROR", msg, *arg)
        syslog(Syslog::Constants::LOG_ERR, "ERROR", msg, *arg)
      end

      private

      def console(level, msg, *arg)
        printf("[#{level}] #{@label}#{msg}\n", *arg) if console_enabled
      end

      def syslog(prio, level, msg, *arg)
        Syslog.open("FILEADMIN") { |log|
          log.log(prio, "[#{level}] #{@label}#{msg}", *arg)
        } if syslog_enabled
      end

    end
  end
end
