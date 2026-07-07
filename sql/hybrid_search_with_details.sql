CREATE OR REPLACE FUNCTION public.hybrid_search_with_details(
  query_embedding vector,
  query_text text,
  match_count integer DEFAULT 10,
  filter jsonb DEFAULT '{}'::jsonb,
  rrf_k integer DEFAULT 50
)
RETURNS TABLE(
  id bigint,
  content text,
  metadata jsonb,
  vector_score double precision,
  keyword_score double precision,
  vector_rank bigint,
  keyword_rank bigint,
  final_score double precision
)
LANGUAGE plpgsql
AS $function$
#variable_conflict use_column
begin
  return query
  with vector_search as (
    select
      d.id,
      (1 - (d.embedding <=> query_embedding))::float as similarity_score,
      rank() over (order by d.embedding <=> query_embedding asc) as rank
    from documents as d
    where d.metadata @> filter
    order by d.embedding <=> query_embedding asc
    limit coalesce(match_count, 10) * 2
  ),
  keyword_search as (
    select
      d.id,
      ts_rank(d.fts, websearch_to_tsquery('english', query_text))::float as keyword_score,
      rank() over (order by ts_rank(d.fts, websearch_to_tsquery('english', query_text)) desc) as rank
    from documents as d
    where d.metadata @> filter and d.fts @@ websearch_to_tsquery('english', query_text)
    order by keyword_score desc
    limit coalesce(match_count, 10) * 2
  )
  select
    coalesce(vector_search.id, keyword_search.id) as id,
    docs.content,
    docs.metadata,
    coalesce(vector_search.similarity_score, 0.0)::float as vector_score,
    coalesce(keyword_search.keyword_score, 0.0)::float as keyword_score,
    vector_search.rank as vector_rank,
    keyword_search.rank as keyword_rank,
    (
      coalesce(1.0 / (rrf_k + vector_search.rank), 0.0) +
      coalesce(1.0 / (rrf_k + keyword_search.rank), 0.0)
    )::double precision as final_score
  from vector_search
  full outer join keyword_search on vector_search.id = keyword_search.id
  join documents docs on docs.id = coalesce(vector_search.id, keyword_search.id)
  order by final_score desc
  limit match_count;
end;
$function$;