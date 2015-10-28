class Searchjob

  def get_results(search_term, search_type, format_type, page, available, subjects, genres, series, authors, location_code)
    if search_type.nil? || search_type == 'keyword'
      search_scheme = self.keyword(search_term)
    elsif search_type == 'author'
      search_scheme = self.author(search_term)
    elsif search_type == 'title'
      search_scheme = self.title(search_term)
    elsif search_type == 'subject'
      search_scheme = self.subject(search_term)
    end
    filters = process_filters(available, subjects, genres, series, authors, format_type, location_code)
    results = Record.search query: {
        bool: search_scheme
      },
      filter:{
        bool: filters
      },
      size: 25,
      from: page,
      min_score: 0.01
      return massage_response(results)
  end

  def keyword(search_term)
    search_scheme = {
          should:[
            {
              multi_match: {
                type: 'phrase',
                query: search_term,
                fields: ['title', 'title.raw', 'title.folded', 'series', 'series.raw'],
                boost: 5,
              }
            },
            {
              multi_match: {
                type: 'best_fields',
                query: search_term,
                fields: ['title', 'title.raw', 'title.folded', 'series', 'series.raw'],
                fuzziness: 1,
                boost: 2
              }
            },
            {
              multi_match: {
                type: 'phrase',
                query: search_term,
                fields: ['author', 'author.raw'],
                boost: 3,
              }
            },
            {
              multi_match: {
                type: 'best_fields',
                query: search_term,
                fields: ['title', 'title.raw', 'title.folded'],
                boost: 1,
                fuzziness: 1
              }
            },
            {
              multi_match: {
                type: 'best_fields',
                query: search_term,
                fields: ['author', 'author.raw'],
                boost: 3,
                fuzziness: 1
              }
            },
            {
              multi_match: {
                type: 'best_fields',
                query: search_term,
                fields: ['subjects','genres', 'abstract', 'contents'],
                fuzziness: 2,
                boost: 2
              }
            },
            {
              multi_match: {
                type: 'best_fields',
                query: search_term,
                fields: ['abstract', 'contents'],
                boost: 2,
                fuzziness: 1
              }
            }
          ]
        }
    return search_scheme
  end

  def author(search_term)
       search_scheme = {
          should:[
          {
            match:
              {author: search_term}},
              {match_phrase: {author: search_term}},
              {fuzzy: {author: search_term},
          }
        ]
      }
    return search_scheme
  end

  def title(search_term)
    search_scheme = {
      should:[
        {
          multi_match: {
            type: 'most_fields',
            query: search_term,
            fields: ['title', 'title.folded'],
            boost: 3
          }
        },
        {
          multi_match: {
            type: 'most_fields',
            query: search_term,
            fields: ['title', 'title.folded'],
            fuzziness: 1
          }
        }
      ]
    }
    return search_scheme
  end

  def subject(search_term)
   search_scheme = {
      should:[
          {
            match:
              {subjects: search_term}},
              {fuzzy: {subjects: search_term},
          }
        ]
      }
    return search_scheme
  end

  def record_id(search_term)
    results = Record.search query:
    {
      term:{
        "id": search_term
      }
    }
    return massage_response(results)
  end

  def massage_response(results)
    massaged_response = results.map do |e|
      record = e['_source']
      record['score'] = e['_score']
      record
    end
    return massaged_response
  end

  def process_filters(available, subjects, genres, series, authors, format_type, location_code)
    filters = Array.new
    if available == 'true'
      filters.push(:term => {"holdings.status": "Available"})
    end

    subjects.each do |s|
      filters.push(:term => {"subjects.raw": URI.unescape(s)})
    end unless subjects.nil?

    genres.each do |s|
      filters.push(:term => {"genres.raw": URI.unescape(s)})
    end unless genres.nil?

    series.each do |s|
      filters.push(:term => {"series.raw": URI.unescape(s)})
    end unless series.nil?

    authors.each do |s|
      filters.push(:term => {"author.raw": URI.unescape(s)})
    end unless authors.nil?

    if location_code && location_code != '' && !location_code.nil?
      location = code_to_location(location_code)
      if location != ''
        filters.push(:term => {"holdings.circ_lib": location})
      end
    end

    format_lock = Array.new

    desired_formats = code_to_formats(format_type)
    desired_formats.each do |f|
      format_lock.push(:term => {'type_of_resource': f})
    end


    filters_hash = {:must => filters, :should => format_lock}
    return filters_hash
  end

  def code_to_formats(format_code)
    formats = Array.new
    if format_code == 'a'
      formats = ['text', 'kit', 'sound recording-nonmusical', 'cartographic']
    elsif format_code == 'g'
      formats = ['moving image']
    elsif format_code == 'j'
      formats = ['sound recording-musical']
    end
    return formats
  end

  def code_to_location(location_code)
    location = ''
    if location_code == '22' || location == nil
      location = ''
    elsif location_code == '23'
      location = 'TADL-WOOD'
    elsif location_code == '24'
      location = 'TADL-IPL'
    elsif location_code == '25'
      location = 'TADL-KBL'
    elsif location_code == '26'
      location = 'TADL-PCL'
    elsif location_code == '27'
      location = 'TADL-FLPL'
    elsif location_code == '28'
      location = 'TADL-EBB'
    end
    return location
  end

end
