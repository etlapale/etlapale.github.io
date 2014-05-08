{-# LANGUAGE OverloadedStrings #-}

import Data.Map (member)
import Data.Monoid (mappend)
import Hakyll
import System.IO.Unsafe
import Text.Pandoc.Options

main :: IO ()
main = hakyllWith myconf $ do
  -- Static files
  match ("images/*"
    .||. "fonts/**"
    .||. "data/**"
    .||. "js/**"
    .||. ".htaccess") $ do
      route   idRoute
      compile copyFileCompiler

  -- CSS are generated by standard Haskell programs using Clay
  match "css/*.hs" $ do
      route   $ setExtension "css"
      compile $ getResourceString >>= withItemBody (unixFilter "runghc" [])

  -- Profile for code projects
  match ("*xico*.md" .||. "projects.md" .||. "projects/*.md")$ do
      route   $ setExtension "html"
      compile $ pandocCompiler
          >>= loadAndApplyTemplate "templates/default.html" xicoCtx
          >>= relativizeUrls

  -- Entry page
  match "*.html" $ do
      route idRoute
      compile $ do
          {-let indexCtx = field "posts" $ \_ ->
                              postList $ fmap (take 3) . recentFirst-}
          getResourceBody
              -- >>= applyAsTemplate indexCtx
              >>= loadAndApplyTemplate "templates/default.html" postCtx
              >>= relativizeUrls

  -- Main website pages
  match "*.md" $ do
      route   $ setExtension "html"
      compile $ pandocCompiler
          >>= loadAndApplyTemplate "templates/default.html" emilCtx
          >>= relativizeUrls

  -- Books and tutorials
  match "doc/*/*.md" $ do
      route   $ setExtension "html"
      compile $ pandocCompilerWith defaultHakyllReaderOptions pandocOptions
          >>= loadAndApplyTemplate "templates/default.html" emilCtx
          >>= relativizeUrls

  -- Blog posts
  match "posts/*.md" $ do
      route $ setExtension "html"
      compile $ pandocCompiler
          >>= loadAndApplyTemplate "templates/post.html"    postCtx
          >>= loadAndApplyTemplate "templates/default.html" postCtx
          >>= relativizeUrls

  -- Blog archive
  {-create ["archive.html"] $ do
      route idRoute
      compile $ do
          let archiveCtx =
                  field "posts" (\_ -> postList recentFirst) `mappend`
                  constField "title" "Archives"              `mappend`
                  emilCtx

          makeItem ""
              >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
              >>= loadAndApplyTemplate "templates/default.html" archiveCtx
              >>= relativizeUrls -}

  -- Templates
  match "templates/*" $ compile templateCompiler

myconf :: Configuration
myconf = defaultConfiguration { ignoreFile = myIgnoreFile }
  where myIgnoreFile ".htaccess" = False
        myIgnoreFile path        = ignoreFile defaultConfiguration path

postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y" `mappend`
  emilCtx

emilCtx :: Context String
emilCtx =
  constField "author" "Émilien Tlapale" `mappend`
  constField "home" "index.html" `mappend`
  listField "navigitems" navigCtx (mapM navigItem items) `mappend`
  defaultContext
  where items = [("Home", "index.html"),
                 ("Research", "research.html"),
                 ("Contact", "contact.html")]

xicoCtx :: Context String
xicoCtx =
  constField "author" "Xīcò" `mappend`
  constField "home" "projects.html" `mappend`
  listField "navigitems" navigCtx (mapM navigItem items) `mappend`
  defaultContext
  where items = [("Projects", "projects.html"),
                 ("Contact", "contact-xico.html")]

navigItem :: (String,Identifier) -> Compiler (Item String)
navigItem (t,u) = return $ Item u t

navigCtx :: Context String
navigCtx =
  field "title" (return . itemBody) `mappend`
  field "url" (return . toFilePath . itemIdentifier) `mappend`
  defaultContext

postList :: ([Item String] -> Compiler [Item String]) -> Compiler String
postList sortFilter = do
    posts   <- sortFilter =<< loadAll "posts/*"
    itemTpl <- loadBody "templates/post-item.html"
    list    <- applyTemplateList itemTpl postCtx posts
    return list

pandocOptions :: WriterOptions
pandocOptions = defaultHakyllWriterOptions
  { writerHTMLMathMethod = MathJax "" }
