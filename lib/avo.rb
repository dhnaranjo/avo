require "zeitwerk"
require_relative "avo/version"
require_relative "avo/engine" if defined?(Rails)

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "html" => "HTML",
  "uri_service" => "URIService",
  "has_html_attributes" => "HasHTMLAttributes"
)
loader.ignore(
  "#{__dir__}/generators",
  # Authorization clients Pundit and ActionPolicy conflict, only load the one we need.
  "#{__dir__}/avo/services/authorization_client"
)
loader.setup

#                                      .//*,,.....,,*/(*
#                                   **,,..............,*#.
#                               ,*,,.....         .....*/#.
#                            **,,....             ....,*/%%
#                        ,**,,.......           . ....*/#&%
#                    **,,,...... .             . ....*/#&&%
#                **,,........ .           .     ...,//#&&&.
#            */*,,..*//***,,,,*/(,..      .. .....*//%&%&*
#         ,/**,..**/******,,***/(###,...........,//(%&&%.
#       /**,,..((//*****////((##%%%%%*.........*//%%&&%
#     ****,...#/**,,,*,*/(#%##%%%%&&&(*,.....,*/(%&&&/
#    /**,....(/*,,,,,,,*(##%%%%%&&&&&(,.....,*(#&&&&.
#  ,//*,.....(/*,,**//(##%%%%&&&&@&&%/,....,*((&&&&*
# .//*,,.....(((//(((##%%%&&&&&&&&@#/,....,*/#%&&&#
# (/**,,......###%%%%%&&&&&&&&&&@#/,,...,,*/#&&&&&
# (/**,,........%%%%%&&&&&&&&@%(*,...,,,*//(&&&&%.
# ///*,,,.........,*#&&&&#(/,,.....,,,*//(%&&&&%*
#  (//**,,,.....................,,,,*//(%&&&&&&*
#   *(///**,,,,............,,,,,,**/((&&&&&&&%.
#     ((///*****,,,,,,,,,,,,***//((&&&&&%&%&#
#       .((((////********///(((%&%&&&&%%%%%
#           (############%%%%%%%%%%%%%%%*
#               ,(############%%%%%#*

module Avo
  ROOT_PATH = Pathname.new(File.join(__dir__, ".."))
  IN_DEVELOPMENT = ENV["AVO_IN_DEVELOPMENT"] == "1"
  PACKED = !IN_DEVELOPMENT
  COOKIES_KEY = "avo"

  class LicenseVerificationTemperedError < StandardError; end

  class LicenseInvalidError < StandardError; end
end

loader.eager_load
