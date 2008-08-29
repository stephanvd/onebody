#!/usr/bin/env ruby

# OneBody Update Agent

# To use, copy this script (updateagent.rb) somewhere.
# The script can run locally or remotely, separately from OneBody.

# Using your membership management software, reporting solution,
# database utility, custom script, etc., export your people
# and family data to two comma separated values (CSV) files, e.g.
# people.csv and families.csv.

# The first row of each file is the attribute headings, and must
# exactly match the attributes available, e.g. see app/models/person.rb
# and app/models/family.rb for all available attributes.

# Or, you may navigate to http://yoursite.com/people.csv and
# http://yoursite.com/families.csv to download current OneBody data
# (if you have any records in the OneBody database).

# "legacy_id" and "legacy_family_id" are two attributes you may use
# in order to track the identity/foreign keys from your existing
# membership management database.

# Edit the first three constants below to match your environment. You
# can get your api key from OneBody (you must be a super user) by
# running the following command (on the server):
#   cd /path/to/onebody
#   rake onebody:api:key EMAIL=admin@example.com
# (use your own email address; account must already exist)

# Your SITE address will probably be something like http://example.com
# (not including ":3000", unless you are running in development mode).

# Run "ruby updateagent.rb" for command line usage and options.

SITE       = 'http://localhost:3000'
USER_EMAIL = 'admin@example.com'
USER_KEY   = 'dafH2KIiAcnLEr5JxjmX2oveuczq0R6u7Ijd329DtjatgdYcKp'

DATETIME_ATTRIBUTES = %w(birthday anniversary updated_at created_at)
BOOLEAN_ATTRIBUTES  = %w(share_* email_changed get_wall_email account_frozen wall_enabled messages_enabled visible friends_enabled member staff elder deacon can_sign_in visible_to_everyone visible_on_printed_directory full_access)
IGNORE_ATTRIBUTES   = %w(updated_at created_at)

require 'date'
require 'csv'
require 'optparse'
require 'rubygems'
require 'highline/import'
require 'activeresource'
require 'digest/sha1'

HighLine.track_eof = false

class Base < ActiveResource::Base
  self.site     = SITE
  self.user     = USER_EMAIL
  self.password = USER_KEY
end

class Person < Base; end
class Family < Base; end

class Hash
  def values_hash(*attrs)
    attrs = attrs.first if attrs.first.is_a?(Array)
    values = attrs.map do |attr|
      value = self[attr.to_s]
      value.respond_to?(:strftime) ? value.strftime('%Y/%m/%d %H:%M') : value
    end
    Digest::SHA1.hexdigest(values.join)
  end
end

class Array
  def include_with_wildcards?(object)
    self.each do |item|
      if item =~ /\*$/
        return true if Regexp.new('^' + Regexp.escape(item.sub(/\*/, ''))).match(object)
      elsif item =~ /^\*/
        return true if Regexp.new(Regexp.escape(item.sub(/\*/, '')) + '$').match(object)
      else
        return true if object == item
      end
    end
    return false
  end
end

class UpdateAgent
  def initialize(filename)
    csv = CSV.open(filename, 'r')
    @attributes = csv.shift
    @data = csv.map do |row|
      hash = {}
      row.each_with_index do |value, index|
        key = @attributes[index]
        next if IGNORE_ATTRIBUTES.include?(key)
        if DATETIME_ATTRIBUTES.include_with_wildcards?(key)
          if value.blank?
            value = nil
          else
            begin
              value = DateTime.parse(value)
            rescue ArgumentError
              puts "Invalid date in #{filename} record #{index} (#{key}) - #{value}"
              exit(1)
            end
          end
        elsif BOOLEAN_ATTRIBUTES.include_with_wildcards?(key)
          if value == '' or value == nil
            value = nil
          elsif %w(no false 0).include?(value.downcase)
            value = false
          else
            value = true
          end
        end
        hash[key] = value
      end
      hash
    end
    @attributes.reject! { |a| IGNORE_ATTRIBUTES.include?(a) }
    @create = []
    @update = []
  end
  
  def ids
    @data.map { |r| r['id'] }.compact
  end
  
  def legacy_ids
    @data.map { |r| r['id'].to_s.empty? ? r['legacy_id'] : nil }.compact
  end

  def compare
    compare_hashes(ids)
    compare_hashes(legacy_ids, true)
  end
  
  def has_work?
    (@create + @update).any?
  end

  def present
    puts 'The following records will be pushed...'
    puts 'type   id     legacy id  name'
    puts '------ ------ ---------- -------------------------------------'
    (@create + @update).each do |row|
      puts "#{resource.name.ljust(6)} #{row['id'].to_s.ljust(10)} #{row['legacy_id'].to_s.ljust(6)} #{name_for(row)}"
    end
    puts
  end
  
  def confirm
    agree('Do you want to continue, pushing these records to OneBody? ')
  end
  
  def push
    puts 'Updating remote end...'
    @create.each do |row|
      puts "Pushing #{resource.name.downcase} #{name_for(row)} (new)"
      record = resource.new
      record.attributes.merge! row.reject { |k, v| k == 'id' }
      record.save
    end
    @update.each do |row|
      puts "Pushing #{resource.name.downcase} #{name_for(row)}"
      record = row['id'] ? resource.find(row['id']) : resource.find_by_legacy_id(row['legacy_id'])
      record.attributes.merge! row.reject { |k, v| k == 'id' }
      record.save
    end
  end
  
  attr_reader :update, :create
  
  class << self; attr_accessor :resource; end
  def resource; self.class.resource; end
  
  protected
  
  def compare_hashes(ids, legacy=false)
    ids.each_slice(50) do |some_ids|
      resource.get(:hashify, :attrs => @attributes, legacy ? :legacy_ids : :ids => ids).each do |record|
        row = @data.detect { |r| legacy ? (r['legacy_id'] == record['legacy_id']) : (r['id'] == record['id']) }
        if record['exists']
          @update << row if row.values_hash(@attributes) != record['hash']
        else
          @create << row
        end
      end
    end
  end
end

class PeopleUpdater < UpdateAgent
  self.resource = Person
  def name_for(row)
    "#{row['first_name']} #{row['last_name']}"
  end
end

if __FILE__ == $0
  options = {:confirm => true}
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby updateagent.rb [options] path/to/people.csv path/to/families.csv"
    opts.on("-y", "--no-confirm", "Assume 'yes' to any questions") do |v|
      options[:confirm] = false
    end
    opts.on("-l", "--log LOGFILE", "Output to log rather than stdout") do |log|
      $stdout = $stderr = File.open(log, 'a')
    end
  end
  opt_parser.parse!
  if ARGV[0] and ARGV[1]
    puts "Update Agent running at #{Time.now.strftime('%m/%d/%Y %I:%M %p')}"
    puts
    agent = PeopleUpdater.new(ARGV[0])
    agent.compare
    if agent.has_work?
      if options[:confirm]
        agent.present
        unless agent.confirm
          puts 'canceled by user'
          puts
          exit
        end
      end
      agent.push
    else
      puts 'Nothing to push'
    end
  else
    puts opt_parser.help
  end
  puts
end
