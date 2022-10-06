class Searchjob

  def get_results(search_term, search_type, format_type, page, available, subjects, genres, series, authors, location_code, shelving_location, sort, physical, minimum_score, fiction)
    if search_type.nil? || search_type == 'keyword'
      search_scheme = self.keyword(search_term)
      if minimum_score != 0.0
        min_score = minimum_score
      else
        min_score = 0.2
      end
    elsif search_type == 'author'
      search_scheme = self.author(search_term)
      if minimum_score != 0.0
        min_score = minimum_score
      else
        min_score = 0.24
      end
    elsif search_type == 'title'
      search_scheme = self.title(search_term)
      if minimum_score != 0.0
        min_score = minimum_score
      else
        min_score = 0.24
      end
    elsif search_type == 'subject'
      search_scheme = self.subject(search_term)
      if minimum_score != 0.0
        min_score = minimum_score
      else
        min_score = 0.6
      end
    elsif search_type == 'series'
      search_scheme = self.series(search_term)
      if minimum_score != 0.0
        min_score = minimum_score
      else
        min_score = 0.6
      end
    elsif search_type == 'shelf'
      search_scheme = self.shelf(shelving_location)
    elsif search_type == 'single_genre'
      search_scheme = self.single_genre(search_term)
      if minimum_score != 0.0
        min_score = minimum_score
      else
        min_score = 0.24
      end
    elsif search_type == 'genre'
      search_scheme = self.genre_search(genres)
    elsif search_type == 'record_id'
      return self.record_id_search(search_term)
    elsif search_type == 'isbn'
      search_scheme = self.isbn(search_term)
      min_score = 3
    elsif search_type == 'call_number'
      search_scheme = self.call_number(search_term)
      min_score = 1
    end
    filters = process_filters(available, subjects, genres, series, authors, format_type, location_code, shelving_location, physical, fiction)
    sort_type = get_sort_type(sort)
    if search_term != nil && search_term != ''
      results = Record.search({query: {
          bool: search_scheme
        },
        filter:{
          bool: filters
        },
        sort: sort_type,
        size: 25,
        from: page,
        min_score: min_score},
        {
          preference: search_term
        })
    else
      results = Record.search({
        filter:{
          bool: filters
        },
        sort: sort_type,
        size: 25,
        from: page,
        min_score: min_score,
        })
    end
      return massage_response(results)
  end

  def keyword(search_term)
    search_scheme = {
      should:[
        {
          multi_match: {
            type: 'phrase',
            query: search_term,
            fields: ['title.folded^10', 'title.raw^10', 'title_short', 'author^7', 'title_alt', 'author_other^3','contents^5','abstract^5','subjects^3','series^6','genres'],
            slop:  100,
            boost: 14
          }
        },
        {
          multi_match: {
            type: 'cross_fields',
            query: search_term,
            fields: ['title.folded^10', 'title.raw^10','author^2','contents','series'],
            slop:  10,
            fuzziness: 1,
            boost: 25
          }
        },
        {
          multi_match: {
            type: 'most_fields',
            query: search_term,
            fields: ['title.folded^10', 'title.raw','author', 'title_alt', 'author_other','contents','abstract','subjects','series','genres'],
            fuzziness: 2,
            slop:  100,
            boost: 1
          }
        },
      ]
    }
    return search_scheme
  end

  def empty_search()
    search_scheme = {}
    return search_scheme
  end

  def isbn(search_term)
    search_scheme ={
      :must =>[
        {:term => {"isbn": search_term}}
      ]
    }

    return search_scheme
  end

  def call_number(search_term)
    search_scheme ={
      :should =>[
        :nested => {
          path: 'holdings',
          query:{
            :match_phrase_prefix => {'holdings.call_number': search_term}
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
            fields: ['title_short', 'title_alt','title.folded', 'title.raw^4'],
            slop:  3,
            boost: 10
          }
        },
        {
          multi_match: {
          type: 'best_fields',
          query: search_term,
          fields: ['title_short', 'title_alt', 'title.folded', 'title.raw^4'],
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

  def series(search_term)
    search_scheme = {
        should:[
            {
              multi_match: {
              type: 'phrase',
              query: search_term,
              fields: ['series'],
              slop:  3,
              boost: 10
              }
            },
            {
              multi_match: {
              type: 'best_fields',
              query: search_term,
              fields: ['series'],
              fuzziness: 2,
              boost: 1
              }
            }
        ]
      }
    return search_scheme
  end

  def single_genre(search_term)
    search_scheme = {
        should:[
            {
              multi_match: {
              type: 'phrase',
              query: search_term,
              fields: ['genres'],
              slop:  3,
              boost: 10
              }
            },
            {
              multi_match: {
              type: 'best_fields',
              query: search_term,
              fields: ['genres'],
              fuzziness: 2,
              boost: 1
              }
            }
        ]
      }
    return search_scheme
  end


  def record_id_search(search_term)
    results = Record.search query:
    {
      term:{
        "id": search_term
      }
    }
    return massage_response(results)
  end

  def shelf(shelving_location)
    shelving_location_filters = Array.new
    shelving_location.each do |s|
      shelving_location_filters.push(:term => {"holdings.location_id": s})
    end
    filters = Array.new
    filters.push(:nested => {
      :path => "holdings",
      :filter =>{
        :bool =>{
          :should =>[
            shelving_location_filters
          ]
        }
      }
    })
    search_scheme = {
      should: filters
    }
  end


  def genre_search(genres)
    filters = Array.new
    genres.each do |s|
      filters.push(:term => {"genres.raw": URI.unescape(s)})
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

  def process_filters(available, subjects, genres, series, authors, format_type, location_code, shelving_location, physical, fiction)
    filters = Array.new
    location = code_to_location(location_code)
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

    if !shelving_location.nil?
      shelving_location_filters = Array.new
      shelving_location.each do |s|
        shelving_location_filters.push(:term => {"holdings.location_id": s})
      end
      if location == ''
        filters.push(:nested => {
          :path => "holdings",
          :filter =>{
            :bool =>{
              :should =>[
                shelving_location_filters
              ]
            }
          }
        })
      else
        filters.push(:nested => {
          :path => "holdings",
          :filter =>{
            :bool =>{
              :must =>[
                {:term => {"holdings.circ_lib": location}}
              ],
              :should =>[
                shelving_location_filters
              ]
            }
          }
        })
      end
    end
          
    #Location filter
    if location_code && location_code != '' && !location_code.nil?
      if location != ''
        filters.push(:bool =>{
          :should =>[
            {:nested => {
              :path => "holdings",
              :filter =>{
                :term => {"holdings.circ_lib": location}
              }
            }},
            {:term => {"electronic": true}}
          ]
        })
      end
    end

    format_lock = Array.new

    # availablity filter
    if available == 'true' && location == ''
      filters.push(:bool =>{
        :should =>[
          {:nested => {
            :path => "holdings",
            :filter =>{
              :bool =>{
                :should =>[
                  {:term => {"holdings.status": "Available"}},
                  {:term => {"holdings.status": "Reshelving"}},
                ]
              }
            }
          }},
          {:term => {"electronic": true}}
        ]  
      })
    elsif available == 'true' 
      filters.push(:bool =>{
        :should =>[
          {:nested => {
            :path => "holdings",
            :filter =>{
              :bool =>{
                :must =>[
                  {:term => {"holdings.circ_lib": location}}
                ],
                :should =>[
                  {:term => {"holdings.status": "Available"}},
                  {:term => {"holdings.status": "Reshelving"}},
                ]
              }
            }
          }},
          {:term => {"electronic": true}}
        ]
      })
    end

    desired_formats = code_to_formats(format_type)
    if format_type != 'ebooks' && format_type != 'large_print'
      desired_formats.each do |f|
        format_lock.push(:term => {'type_of_resource': f})
      end
    elsif format_type == 'ebooks'
      ebook_sources = Array.new
      desired_formats[0].each do |f|
        ebook_sources.push({:term => {'source': f}})
      end
      ebook_formats = Array.new
      desired_formats[1].each do |f|
        ebook_formats.push({:term => {'type_of_resource': f}})
      end
      filters.push(:bool =>{
        :should => ebook_sources
      })
      filters.push(:bool =>{
        :should => ebook_formats
      })
    elsif format_type == 'large_print'
      filters.push(:bool =>{
        :should =>[
          :nested => {
            path: 'holdings',
            query:{
              :match_phrase_prefix => {'holdings.call_number': 'LP'}
            }
          }
        ]
      })
    end

    fiction_filter = fiction
    
    if fiction_filter == "true"
      filters.push(:bool =>{
          :should =>[
            {:term => {"fiction": true}},
          ]
        })
    elsif fiction_filter == "false"
        filters.push(:bool =>{
          :should =>[
            {:term => {"fiction": false}},
          ]
        })
    end

    #physical only filter
    if physical == true || physical == 'true'
      filters.push(:term => {'electronic':false})
    end

    filters_hash = {:must => filters, :should => format_lock}
    return filters_hash
  end

  def code_to_formats(format_code)
    formats = Array.new
    if format_code == 'a'
      formats = ['text', 'kit', 'cartographic']
    elsif format_code == 'g'
      formats = ['moving image']
    elsif format_code == 'j'
      formats = ['sound recording-musical']
    elsif format_code == 'ebooks'
      formats = [['Safari','OverDrive','Hoopla'],['text', 'kit', 'sound recording-nonmusical', 'cartographic', 'software, multimedia']]
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
    elsif location_code == '44'
      location = 'KCL'
    elsif location_code == '48'
      location = 'KPS-BSE'
    elsif location_code == '49'
      location = 'KPS-CSI'
    elsif location_code == '50'
      location = 'KPS-RCE'
    elsif location_code == '51'
      location = 'KPS-KMS'
    elsif location_code == '52'
      location = 'KPS-KHS'
    end
    return location
  end

  def get_sort_type(sort)
    sort_type = Array.new
    if sort == nil || sort == '' || sort == 'relevancy'
      sort_type.push("_score")
      sort_type.push({ "author.raw": "asc" })
      sort_type.push({ "title_nonfiling.sort": "asc" })
    else
      if sort == 'titleAZ'
        sort_type.push({ "title_nonfiling.sort": "asc" })
      elsif sort == 'titleZA'
        sort_type.push({ "title_nonfiling.sort": "desc" })
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
