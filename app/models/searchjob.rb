class Searchjob
  
  def get_results(search_term, search_type, format_type, page, available, subjects, genres, series, authors)
    if search_type.nil? || search_type == 'keyword'
      search_scheme = self.keyword(search_term)
    elsif search_type == 'author'
      search_scheme = self.author(search_term)
    elsif search_type == 'title'
      search_scheme = self.title(search_term)
    elsif search_type == 'subject'
      search_scheme = self.subject(search_term)
    end
    filters = test = process_filters(available, subjects, genres, series, authors, format_type)
    results = Record.search query: {
        bool: search_scheme
      },
      filter:{
        bool: filters
      },
      size: 49,
      from: page,
      min_score: 0.1
      return massage_response(results)
  end

  def keyword(search_term)
    search_scheme = { 
          should:[ 
            {
              multi_match: {
                type: 'most_fields', 
                query: search_term, 
                fields: ['title', 'title.folded','author','subjects','genres','series','abstract', 'contents'],
                boost: 3
              }
            },
            {
              multi_match: {
                type: 'best_fields', 
                query: search_term, 
                fields: ['title', 'title.folded', 'author'],
                boost: 3,
                fuzziness: 2
              }
            },
            {
              multi_match: {
                type: 'most_fields',
                query: search_term,
                fields: ['subjects','genres','series'],
                boost: 2,
                fuzziness: 1
              }
            },
            {
              multi_match: {
                type: 'best_fields',
                query: search_term,
                fields: ['abstract', 'contents'],
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

  def process_filters(available, subjects, genres, series, authors, format_type)
    filters = Array.new
    if available == 'true'
      filters = filters.push({:term => {"holdings.status": "Available"}})
    end

    subjects.each do |s|
      filters = filters.push({:term => {"subjects.raw": s}})
    end unless subjects.nil?

    genres.each do |s|
      filters = filters.push({:term => {"genres.raw": s}})
    end unless genres.nil?

    series.each do |s|
      filters = filters.push({:term => {"series.raw": s}})
    end unless series.nil?

    authors.each do |s|
      filters = filters.push({:term => {"author.raw": s}})
    end unless authors.nil?

    format_lock = Array.new

    desired_formats = code_to_formats(format_type)
    desired_formats.each do |f|
      format_lock = format_lock.push({:term => {'type_of_resource': f}})
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

end