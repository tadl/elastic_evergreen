class Searchjob
  def keyword(search_term, page)
    results = Record.search query: 
      {
        bool:{ 
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
            # {
            #   multi_match: {
            #     type: 'best_fields', 
            #     query: search_term, 
            #     fields: ['author'],
            #     boost: 2,
            #   }
            # }
            # {
            #   multi_match: {
            #     type: 'phrase', 
            #     query: search_term, 
            #     fields: ['title', 'title.folded'],
            #     fuzziness: 1,
            #   }
            # },
   
            # {
            #   match_phrase: {
            #     author: search_term
            #   }
            # }, 
            # {
            #   fuzzy: {
            #     author: search_term
            #   }
            # },
            # {
            #   multi_match: {
            #     query: search_term,
            #     fields: ['abstract','author'],
            #     fuzziness: 2
            #   }
            # }
          ]
        }
      },
      size: 49,
      from: page,
      min_score: 0.1
    return massage_response(results)
  end

  def author(search_term, page)
    results = Record.search query: 
    {
      bool:{ 
        should:[
          {
            match: 
              {author: search_term}}, 
              {match_phrase: {author: search_term}}, 
              {fuzzy: {author: search_term},
          }
        ]
      }
    },
    size: 49,
    from: page,
    min_score: 0.3
    return massage_response(results)
  end

  def title(search_term, page)
    results = Record.search query: 
      {
        multi_match: {
          type: 'most_fields', 
          query: search_term, 
          fields: ['title', 'title.folded'],
          fuzziness: 1
        } 
      },
      size: 49,
      from: page,
      min_score: 0.3
    return massage_response(results)
  end

  def subject(search_term, page)
    results = Record.search query: 
      {
        multi_match: {
          type: 'most_fields', 
          query: search_term, 
          fields: ['subjects','genres'],
          fuzziness: 1
        } 
      },
      size: 49,
      from: page,
      min_score: 0.3
    return massage_response(results)
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
end