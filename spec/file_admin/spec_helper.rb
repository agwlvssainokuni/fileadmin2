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

def create_subject(klass1, klass2, label, conf, conf_collect)
  klass1.new(label).tap do |obj|
    conf.each do |k, v|
      obj.method("#{k}=".to_sym).call(v)
    end
    obj.collector = klass2.new
    conf_collect.each do |k, v|
      obj.collector.method("#{k}=".to_sym).call(v)
    end
  end
end
