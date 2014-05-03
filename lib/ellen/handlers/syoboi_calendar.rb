require "active_support/core_ext/enumerable"
require "active_support/core_ext/numeric/time"
require "active_support/core_ext/time"

module Ellen
  module Handlers
    class SyoboiCalendar < Base
      on(/list anime\z/, name: "list", description: "List today's anime")

      def list(message)
        message.reply(descriptions.join("\n"))
      end

      private

      def descriptions
        programs_sorted_by_started_at.map do |program|
          "#{program.started_at_in_string} #{titles_index_by_id[program.title_id].title} #{program.count}"
        end
      end

      def client
        @client ||= ::SyoboiCalendar::Client.new
      end

      def titles_index_by_id
        @titles_by_id ||= titles.index_by(&:id)
      end

      def titles
        [get_titles.TitleLookupResponse.TitleItems.TitleItem].flatten.map do |title|
          Ellen::SyoboiCalendar::Title.new(
            id: title.id,
            title: title.Title,
            short_title: title.ShortTitle,
          )
        end
      end

      def get_titles
        client.titles(title_options)
      end

      def title_options
        {
          title_id: title_ids_in_programs.join(",")
        }
      end

      def title_ids_in_programs
        programs.map do |program|
          program.title_id
        end
      end

      def programs_sorted_by_started_at
        programs.sort_by(&:started_at)
      end

      def programs
        @programs ||= [get_programs.ProgLookupResponse.ProgItems.ProgItem].flatten.map do |program|
          Ellen::SyoboiCalendar::Program.new(
            count: program.Count,
            channel_id: program.ChID,
            sub_title: program.STSubTitle,
            title_id: program.TID,
            started_at: program.StTime,
            finished_at: program.EdTime,
          )
        end
      end

      def get_programs
        client.programs(program_options)
      end

      def program_options
        {
          played_from: played_from,
          played_to: played_to,
        }
      end

      def played_from
        Time.now
      end

      def played_to
        Time.now.end_of_day
      end
    end
  end
end
