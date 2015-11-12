class Searchjob

  def get_results(search_term, search_type, format_type, page, available, subjects, genres, series, authors, location_code, shelving_location, sort)
    if search_type.nil? || search_type == 'keyword'
      search_scheme = self.keyword(search_term)
      min_score = 0.01
    elsif search_type == 'author'
      search_scheme = self.author(search_term)
      min_score = 0.09
    elsif search_type == 'title'
      search_scheme = self.title(search_term)
      min_score = 0.01
    elsif search_type == 'subject'
      search_scheme = self.subject(search_term)
      min_score = 0.6
    elsif search_type == 'shelf'
      search_scheme = self.shelf(shelving_location)
    end
    filters = process_filters(available, subjects, genres, series, authors, format_type, location_code, shelving_location)
    sort_type = get_sort_type(sort)
    results = Record.search query: {
        bool: search_scheme
      },
      filter:{
        bool: filters
      },
      sort: sort_type,
      size: 25,
      from: page,
      min_score: min_score
      return massage_response(results)
  end

  def keyword(search_term)
    search_scheme = {
        should:[
          {
            multi_match: {
            type: 'phrase',
            query: search_term,
            fields: ['title_short^12','title.folded^11', 'title.raw^12','author^8', 'author_other^3','contents','abstract^3','subjects^3','series^9','genres'],
            slop:  3,
            boost: 14
            }
          },
          {
            multi_match: {
            type: 'best_fields',
            query: search_term,
            fields: ['title_short^12','title.folded^11', 'title.raw^12','author^8', 'author_other^3','contents','abstract^3','subjects^3','series^9','genres'],
            boost: 5
            }
          },
          {
            multi_match: {
            type: 'most_fields',
            query: search_term,
            fields: ['title_short^11', 'title.folded^11', 'title.raw^12','author^8', 'author_other^2','contents','abstract^3','subjects^3','series^9','genres'],
            fuzziness: 2,
            boost: 5
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
              multi_match: {
              type: 'phrase',
              query: search_term,
              fields: ['author^3', 'author_other'],
              slop:  3,
              boost: 10
              }
            },
            {
              multi_match: {
              type: 'best_fields',
              query: search_term,
              fields: ['author^3', 'author_other'],
              fuzziness: 2,
              boost: 1
              }
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
            type: 'phrase',
            query: search_term,
            fields: ['title_short','title.folded', 'title.raw^4'],
            slop:  3,
            boost: 10
          }
        },
        {
          multi_match: {
          type: 'best_fields',
          query: search_term,
          fields: ['title_short', 'title.folded', 'title.raw^4'],
          fuzziness: 2,
          boost: 1
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
              multi_match: {
              type: 'phrase',
              query: search_term,
              fields: ['subjects^3', 'abstract', 'contents'],
              slop:  3,
              boost: 10
              }
            },
            {
              multi_match: {
              type: 'best_fields',
              query: search_term,
              fields: ['subjects^3', 'abstract', 'contents'],
              fuzziness: 2,
              boost: 1
              }
            }
        ]
      }
    return search_scheme
  end

  def record(search_term)
    results = Record.search query:
    {
      term:{
        "id": search_term
      }
    }
    return massage_response(results)
  end

  def shelf(shelving_location)
    filters = Array.new
    shelving_location.each do |s|
      filters.push(:term => {"holdings.location_id": s})
    end
    search_scheme = {
      should: filters
    }
  end

  def massage_response(results)
    massaged_response = results.map do |e|
      record = e['_source']
      record['score'] = e['_score']
      record
    end
    return massaged_response
  end

  def process_filters(available, subjects, genres, series, authors, format_type, location_code, shelving_location)
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

    shelving_location.each do |s|
      filters.push(:term => {"holdings.location_id": shelving_location})
    end unless shelving_location.nil?

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

  def get_sort_type(sort)
    sort_type = Array.new
    if sort == nil || sort == '' || sort == 'relevancy'
      sort_type.push("_score")
      sort_type.push({ "author.raw": "asc" })
      sort_type.push({ "title.raw": "asc" })
    else
      if sort == 'titleAZ'
        sort_type.push({ "title.raw": "asc" })
      elsif sort == 'titleZA'
        sort_type.push({ "title.raw": "desc" })
      elsif sort == 'AuthorAZ'
        sort_type.push({ "author.raw": "asc" })
      elsif sort == 'AuthorZA'
        sort_type.push({ "author.raw": "desc" })
      elsif sort == 'createDESC'
        sort_type.push({"create_date": "desc" })
        sort_type.push({"sort_year": "desc" })
      elsif sort == 'createASC'
        sort_type.push({"create_date": "asc" })
        sort_type.push({"sort_year": "asc" })
      elsif sort == 'pubdateDESC'
        sort_type.push({"sort_year": "desc" })
        sort_type.push({"create_date": "desc" }) 
      elsif sort == 'pubdateASC'
        sort_type.push({"sort_year": "asc" })
        sort_type.push({"create_date": "asc" })
      end
      sort_type.push("_score")
    end
    return sort_type
  end

end
