class Searchjob
  def keyword(search_term)
    results = Record.search query: 
      {
        bool:{ 
          should:[ 
            {
              multi_match: {
                type: 'most_fields', 
                query: search_term, 
                fields: ['title', 'title.folded','author'],
                boost: 3
              }
            },
            {
              multi_match: {
                type: 'best_fields', 
                query: search_term, 
                fields: ['title', 'title.folded', 'author'],
                boost: 2,
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
      size: 121,
      from: 0,
      min_score: 0.3
    return massage_response(results)
  end

  def author(search_term)
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
    size: 24,
    min_score: 0.3
    return massage_response(results)
  end

  def title(search_term)
    results = Record.search query: 
      {
        multi_match: {
          type: 'most_fields', 
          query: search_term, 
          fields: ['title', 'title.folded']
        } 
      }
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