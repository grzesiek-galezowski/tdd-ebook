$ROOT = Pathname.pwd
$MANUSCRIPT_DIR = $ROOT + "manuscript"
$MANUSCRIPT_IMAGES_DIR = $MANUSCRIPT_DIR + "images"
$MANUSCRIPT_COVER_IMAGE = $MANUSCRIPT_IMAGES_DIR + "homemade_title_page.png"
$BOOK_CHAPTERS_LIST = "Book.txt"
$SAMPLE_CHAPTERS_LIST = "Sample.txt"

$MANUSCRIPT_BOOK_CHAPTERS_LIST = $MANUSCRIPT_DIR + $BOOK_CHAPTERS_LIST
$MANUSCRIPT_SAMPLE_CHAPTERS_LIST = $MANUSCRIPT_DIR + $SAMPLE_CHAPTERS_LIST

$ROOT_DIR_COVER_IMAGE = $ROOT + "cover_real.png"



def for_each_manuscript_file
  errors = DetectedErrors.new
  Dir.foreach($MANUSCRIPT_DIR) do |filename|
    rooted_filename = $MANUSCRIPT_DIR + filename
    
    if filename == '.' or filename == '..'
      puts "skipping #{rooted_filename} - one of . or .."
      next
    end

    if not File.file?(rooted_filename)
      puts "skipping #{rooted_filename} - not a file"
      next
    end
    
    puts "Processing #{rooted_filename}"
	  yield rooted_filename, errors  
  
  end
  errors.assert_none

end

def extract_all_uris_from(filename)
  URI.extract(File.read(filename), /http(s)?|mailto/).map { |el| el.gsub(/[.),:]+$/, '') }
end

class DetectedErrors
  def initialize
    @errors = []
  end
  
  def add(message)
    @errors.push message
  end 
  
  def assert_none
    if not @errors.any?
      puts "no errors detected".green
    else
      puts @errors.each { |err| puts err.red }
      puts "#{@errors.length} errors detected".red
      raise "build failed"
    end
  end
end

def validate_uris uris, errors
  uris.each do | uri |
    begin
      url = URI.parse(uri)
      req = Net::HTTP.new(url.host, url.port)
      
      if url.scheme == "https" then 
        req.use_ssl = true
        req.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this
        req.read_timeout = 60
      end
      
      res = req.request_head(url.path)
      
      message = "#{uri} => #{res.code}, #{res.message}"
      if res.code.to_i == 400 or res.code.to_i == 403 then 
        puts message.yellow
      elsif res.code.to_i > 400 then
        raise message
      else
        puts message.green
      end
      
    rescue Exception => e
      errors.add "Error while checking #{uri}: #{e}"
    end
  end
end


