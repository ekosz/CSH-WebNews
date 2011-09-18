NEWS_SERVER = 'news.csh.rit.edu'
PROFILES_URL = 'https://members.csh.rit.edu/profiles/member/'
WIKI_URL = 'https://wiki.csh.rit.edu/wiki/User:'
LOCAL_EMAIL_DOMAIN = '@csh.rit.edu'

DATE_FORMAT = '%-m/%-d/%Y %-I:%M%P'

ACTIVITY_FEED_EXCLUDE = /^(control|csh\.lists|csh\.test)/

PERSONAL_CODES = { nil => 0, :mine_in_thread => 1, :mine_reply => 2, :mine => 3 }.freeze
PERSONAL_CLASSES = PERSONAL_CODES.keys.map(&:to_s).freeze
