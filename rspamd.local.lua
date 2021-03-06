-- --------------------------
-- rspamd RegEx Module 're = /Foo/i{mime}'
-- --------------------------

-- {line suffix}
--  {header} - header regexp
--  {raw_header} - undecoded header regexp (e.g. without quoted-printable decoding)
--  {mime_header} - MIME header regexp (applied for headers in MIME parts only)
--  {all_header} - full headers content (applied for all headers undecoded and for the message only - not including MIME headers)
--  {body} - raw message regexp
--  {mime} - part regexp without HTML tags
--  {raw_mime} - part regexp with HTML tags
--  {sa_body} - spamassassin BODY regexp analogue(see http://spamassassin.apache.org/full/3.4.x/doc/Mail_SpamAssassin_Conf.txt)
--  {sa_raw_body} - spamassassin RAWBODY regexp analogue
--  {url} - URL regexp
--  {selector} - from 1.8: selectors regular expression (must include name of the registered selector)
--  {words} - unicode normalized and lowercased words extracted from the text (excluding URLs), subject and From displayed name
--  {raw_words} - same but with no normalization (converted to utf8 however)
--  {stem_words} - unicode normalized, lowercased and stemmed words extracted from the text (excluding URLs), subject and From displayed name
-- Flag
--  Each regexp also supports the following flags:
--  
--  i - ignore case
--  u - use utf8 regexp
--  m - multiline regexp - treat string as multiple lines. That is, change “^” and “$” from matching the start of the string’s first line and the end of its last line to matching the start and end of each line within the string
--  x - extended regexp - this flag tells the regular expression parser to ignore most whitespace that is neither backslashed nor within a bracketed character class. You can use this to break up your regular expression into (slightly) more readable parts. Also, the # character is treated as a metacharacter introducing a comment that runs up to the pattern’s closing delimiter, or to the end of the current line if the pattern extends onto the next line.
--  s - dotall regexp - treat string as single line. That is, change . to match any character whatsoever, even a newline, which normally it would not match. Used together, as /ms, they let the . match any character whatsoever, while still allowing ^ and $ to match, respectively, just after and just before newlines within the string.
--  O - do not optimize regexp (rspamd optimizes regexps by default)
--  r - use non-utf8 regular expressions (raw bytes). This is default true if raw_mode is set to true in the options section.



local cnf = config['regexp'] -- Reconfigure or configure NEW Local Symbols (cnf)

-- EXAMPLES
--cnf['FROM_NETFLIX'] = {
--    re = 'From=/.*netflix.com*/i{header}',
--    score = -2.5,
--}
--cnf['HEADER_CONTAINS_NETFLIX'] = {
--    re = 'From=/.*netflix*/i{header}',
--    description = 'From Header contains Netflix somewhere',
--    score = 2.5,
--}
-- --------------------------
-- NO SPF HELO revd by Relay
-- --------------------------

--local mynohelo1 = '/SPF_HELO_NONE/i{raw_header}' 

--cnf['RLY_NOSPFHELO'] = {
--	re = string.format('(%s)', mynohelo1), -- use string.format to create expression
--	score = 40,
--	description = 'NO SPF HELO received by relay',
--}
-- --------------------------
-- Initial Netflix spam Test
-- --------------------------

local myre1 = 'From=/.*netflix.com.*/i{header}' -- Mind local here
local myre2 = 'From=/.*netflix*/i{header}'
local myre3 = '/NETFLIX/i{body}' -- Check the raw body for anycase Netflix

cnf['NETFLIX_YETNOT_NETFLIX'] = {
	re = string.format('!(%s) && ((%s) || (%s))', myre1, myre2, myre3), -- use string.format to create expression
	score = 40,
	description = 'From Contains Netflix AND NOT Mailed from Netflix.com',
}

-- Extend Netflix to other problematic domains - i.e. Apple - Lazy spammers but won't detect spoofs
local myre11 = 'From=/.*(dhl|fedex|apple|amazon|samsung|paypal|google).com.*/i{header}' 
local myre22 = 'From=/.*(dhl|fedex|apple|amazon|samsung|paypal|google).*/i{header}'

cnf['BOGUS_MAIL_FROM_APPLE'] = {
	re = string.format('!(%s) && (%s)', myre11, myre22), -- use string.format to create expression
	score = 40,
	description = 'From Contains Apple/DHL/Amazon/Samsung/Paypal AND NOT Mailed from that domain',
}
-- Misc subject or body words of no interest
local myrew1 = 'Subject=/.*erection|bitcoin|bit coin|business (lead|list).*/i{header}' 
local myrew2 = '/erection|bitcoin|bit coin|business (lead|list)/i{body}' -- Check the raw body

cnf['SUBJ_NO_INTEREST'] = {
	re = string.format('(%s) || (%s)', myrew1, myrew2), -- use string.format to create expression
	score = 40,
	description = 'Misc subject or body words of no interest (Bitcoin / ED Medz)',
}



-- Local User Email in Subject
local myren1 = 'Subject=/.*(user1|user2)@.*/i{header}' -- obfuscated

cnf['SUBJECT_CONTAINS_LOCALUSEREMAIL'] = {
    re = string.format('(%s)', myren1),
    description = 'Subject contains Local User email address',
    score = 40,
}

-- Polite Intro to User in Body
local myrbn1 = '/(Hi|Hello|Dear|Congratulations) (john|mary)@.*/i{body}' -- obfuscated

cnf['BODY_CONTAINS_POLITE_LOCALUSEREMAIL'] = {
    re = string.format('(%s)', myrbn1),
    description = 'Body contains Polite intro & Local User email address',
    score = 40,
}

-- --------------------------
-- Subject & Body Matching --
-- --------------------------
local myneib1 = 'Subject=/.*(Neighbou?r|next door|f[ua5&%]ck).*/i{header}'
local myneib2 = '/.*f[ua5&%]ck.*/i{body}'

cnf['SUBJ_NEXTDOOR'] = {
    re = string.format('(%s) || (%s)', myneib1, myneib2),
    description = 'Subject/Body re Neighbour or next Door or H*ck',
    score = 20,
}

local mypharma1 = 'Subject=/.*viagra|pills|health secret|pharmacy.*/i{header}'
local mypharma2 = '/.*viagra|pills|health secret|pharmacy.*/i{body}'

cnf['MY_VIAGRA'] = {
    re = string.format('(%s) || (%s)', mypharma1, mypharma2),
    description = 'Subject or Body re Pharma / Viagra / Pills / Health Secret',
    score = 20,
}



local myrush = 'Subject=/.*This is your Final|Last (Chance|Reminder|Notice).*/i{header}'
cnf['BETTER_HURRY'] = {
    re = string.format('(%s)', myrush),
    description = 'Final Reminders Spam',
    score = 5,
}

-- --------------------------------------------------
-- Text matching
-- --------------------------------------------------
-- combine DOC_OR_FAX_RECVD with HAS_ATTACHMENT in local.d/composites.conf to create a rule/score
-- couldn't get 'local myvar1 = [[has_symbol(HAS_ATTACHMENT)]]' & 'rspamd_config:register_dependency('DOC_OR_FAX_RECVD', 'HAS_ATTACHMENT')' to work.......
local mydoc1 = 'Subject=/.*You have (1|received )?(a )?new (fax|document)+.*/i{header}'
--local mydoc2 = [[has_symbol(HAS_ATTACHMENT)]]
cnf['DOC_OR_FAX_RECVD'] = {
--  re = string.format('(%s) && (%s)', mydoc1, mydoc2),
    re = string.format('(%s)', mydoc1),
    description = 'Surprise - Your non existent fax sent you something....',
    score = 0.0,
}

local mypass1 = '/.*I (do )?(know )?[a-zA-Z0-9]{1,99} one of your pass.*/i{body}'
local mypass2 = '/.*I actually (installed|placed) a (malware|software) on the (18+|xxx) (streaming|videos|video clips) ((porn|porno|sexually graphic)).*/i{body}'
cnf['MY_LEAKED_PWD'] = {
    re = string.format('(%s) || (%s)', mypass1, mypass2),
    description = 'Gosh, you know my password.....',
    score = 40,
}
-- --------------------------------------------------
-- English please, I'm a boomer Australian
-- --------------------------------------------------

local ok_langs = {
  ['en'] = true,
}

rspamd_config.LANG_FILTER = {
  callback = function(task)
    local any_ok = false
    local parts = task:get_text_parts() or {}
    local ln
    for _,p in ipairs(parts) do
      ln = p:get_language() or ''
      local dash = ln:find('-')
      if dash then
        -- from zh-cn to zh
        ln = ln:sub(1, dash-1)
      end
      if ok_langs[ln] then
        any_ok = true
        break
      end
    end
    if any_ok or not ln or #ln == 0 then
      return false
    end
    return 1.0,ln
  end,
  score = 150.0,
  description = 'no ok languages',
}

-- rspamd_config:register_dependency('DOC_OR_FAX_RECVD', 'HAS_ATTACHMENT')
