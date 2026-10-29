-- One JSON object per customer with at least one quote. One row per line in the export.
-- Oracle 19c+; one job per quote is enforced by the integrity overlay.
select
    json_object(
        '_id' value c.cust_no,
                'customer_name' value c.cust_gname
                                      || ' '
                                      || c.cust_fname,
                'customer_business' value nvl(
            c.cust_bname,
            '-'
        ),
                'customer_address' value c.cust_street
                                         || ', '
                                         || c.cust_town
                                         || ', '
                                         || c.cust_pcode,
                'customer_phone' value c.cust_contact_no,
                'customer_stats' value
            json_object(
                'number_of_quotes' value count(q.quote_no),
                        'number_of_jobs' value count(j.job_no),
                        'total_paid_jobcost' value nvl(
                    trim(to_char(
                        sum(
                            case
                                when j.job_payment_made = 'Y' then
                                    nvl(
                                        j.job_cost,
                                        q.quote_cost
                                    )
                            end
                        ),
                        '$999,990.00'
                    )),
                    '-'
                ),
                        'total_unpaid_jobcost' value nvl(
                    trim(to_char(
                        sum(
                            case
                                when j.job_payment_made = 'N' then
                                    nvl(
                                        j.job_cost,
                                        q.quote_cost
                                    )
                            end
                        ),
                        '$999,990.00'
                    )),
                    '-'
                )
            ),
                'quotes' value json_arrayagg(
            json_object(
                'quote_no' value q.quote_no,
                        'quote_prepared_on' value to_char(
                    q.quote_prepared_date,
                    'DD-Mon-YYYY', 'NLS_DATE_LANGUAGE=English'
                ),
                        'preferred_start_date' value to_char(
                    q.quote_pref_start_date,
                    'DD-Mon-YYYY', 'NLS_DATE_LANGUAGE=English'
                ),
                        'start_location' value q.quote_start_location,
                        'end_location' value q.quote_end_location,
                        'quote_cost' value trim(to_char(
                    q.quote_cost,
                    '$999,990.00'
                )),
                        'assigned_to_job' value
                    case
                        when j.job_no is null then
                            'N'
                        else
                            'Y'
                    end,
                        'job_cost' value
                    case
                        when j.job_no is null then
                            '-'
                        else
                            trim(to_char(
                                nvl(
                                    j.job_cost,
                                    q.quote_cost
                                ),
                                '$999,990.00'
                            ))
                    end
            )
         order by q.quote_no returning clob)
    returning clob)
  from customer c
  join quote q
on c.cust_no = q.cust_no
  left outer join job j
on q.quote_no = j.quote_no
 group by c.cust_no,
          c.cust_gname,
          c.cust_fname,
          c.cust_bname,
          c.cust_street,
          c.cust_town,
          c.cust_pcode,
          c.cust_contact_no
 order by c.cust_no;
