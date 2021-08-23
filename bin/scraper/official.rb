#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'
require 'pry'
require 'open-uri/cached'

class MemberList
  class MemberPage < Scraped::HTML
    field :name do
      row('Name').text.tidy
    end

    field :start_date do
      Date.parse(role_and_date.last).to_s
    end

    field :position do
      [role_and_date.first, ministry.sub('Ministry', 'Minister')] - ['Minister']
    end

    field :dob do
      Date.parse(birth_date).to_s
    end

    field :ministry do
      (row('Ministry') || row('Responsible')).text.tidy
    end

    private

    def table
      noko.css('#maincontent_reptexts_div_0 table')
    end

    def row(str)
      table.xpath(".//tr/td[contains(., '#{str}')]/following-sibling::td").first
    end

    def function
      (row('Function') || row('Position')).text.tidy
    end

    def role_and_date
      function.split(' since ')
    end

    def birth_date
      (row('Date of birth') || row('Date of Birth')).text.tidy
    end
  end

  class Member
    def name
      Name.new(
        full:     noko.text.tidy,
        prefixes: %w[Dr]
      ).short
    end

    def position
      page.position
    end

    field :dob do
      page.dob
    end

    field :source_url do
      URI.join('https://www.regierung.li/members-of-government', noko.attr('href'))
    end

    private

    def page
      @page ||= MemberPage.new(response: Scraped::Request.new(url: source_url).response)
    end
  end

  class Members
    def member_items
      super.reject { |mem| mem.name.start_with? 'Alternate' }
    end

    def member_container
      noko.css('#maincontent_reptexts_div_0 li a')
    end
  end
end

file = Pathname.new 'html/official.html'
puts EveryPoliticianScraper::FileData.new(file).csv
