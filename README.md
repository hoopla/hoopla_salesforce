hoopla_salesforce
=================

A nifty bundle of dev and deployment tools for working on the (Sales)force.com platform.

Features
========

1. Generates new empty projects
2. Deploys your project with Rake
3. Generates *-meta.xml for any files that are missing it
4. Runs tests on deploy and prints results in ANSI color
5. Auto-packages folders in src/resource as staticresources
6. Undeploys your project (destructiveChanges.xml is auto-generated)
7. Pre-processes any VisualForce or Apex files with ERB
8. Generates static test pages from VisualForce pages
9. Runs tests via the Web UI (as results often differ from deploy tests) [experimental]
10. Makes pancakes (pending)

Usage
=====

Install it with:

    (sudo) gem install hoopla_salesforce

There are a lot of features in here, so the rest of this document will go over how they work.

Generating new projects
-----------------------

Just run:

    hoopla_salesforce init myproject

This will create an folder called myproject that looks like this:

    myproject/
    ├── lib
    ├── Rakefile
    └── src
        ├── applications
        ├── classes
        ├── objects
        ├── package.xml
        ├── pages
        ├── resources
        ├── tabs
        └── triggers

Once this is done, drop the enterprise.xml and metadata.xml for your org into `lib/` and update the `Rakefile` to reflect your username, password and security token. Now your project is ready to deploy. Run `rake -T` to show the available rake tasks.

Deploy your projects with rake
------------------------------

Deploy your project using `rake hsf:deploy:development`. Or if you change the environment name of your DeployTask, use whatever you specified in place of 'development'.

If you need to see the full deployment output run it with `FULL_OUTPUT=true`. Currently coverage information is only available in the full output. The default output will include colorized information about what's been added, updated, tests run, any failures or compilation problems.

Generating meta.xml files
-------------------------

During deployment, we'll generate any missing meta.xml files for your assets. This currently supports generation for classes, pages, documents, static resources, and triggers. If you already have meta.xml files for your resources, the gem will skip those and include your files for deployment.

Autopackaging of static resources
---------------------------------

As part of deployment, any folders in src/resources will get zipped up as static resources. So for example if you had a folder `src/resources/Performance` the contents of this folder will get zipped into `src/staticresources/Performance.resource`. This makes dealing with zipped CSS/JavaScript much easier.

Undeploying your project
------------------------

To undeploy your project run `rake hsf:undeploy:development`. This will scan your src folder and generate the appropriate destructiveChanges.xml file used by Salesforce to undeploy your code.

Note that undeployed fields are still left in the "deleted fields" section of the site. Once you have two copies of a deleted field, you can't re-deploy that field without first cleaning up the deleted fields via the WebUI. Automatic erasing of fields is a planned feature to avoid this headache.

Pre-processing with ERB
-----------------------

If you append `.erb` to any file in your project, it will get processed through Erubis prior to deployment. This makes it possible to DRY up a lot of your XML, abstract common patterns and even write simple Apex macros.

Just before the templates are run, the deployer will look for `lib/template_helper.rb` and load that. In this file you can mix your own methods into the template processors. The following example allows you to use `<%= object do %>...<% end %>` in an object file to avoid writing the XML boilerplate that's required by salesforce.

    class HooplaSalesforce::TemplateProcessor::Generic
      def object(&block)
        code = <<-XML.margin
          <?xml version="1.0" encoding="UTF-8"?>
          <CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
            <deploymentStatus>Deployed</deploymentStatus>
            <sharingModel>ReadWrite</sharingModel>
            #{capture &block}
          </CustomObject>
        XML
      end
    end

The currently available processors are:

* `HooplaSalesforce::TemplateProcessor::VisualForce` - used for processing page files
* `HooplaSalesforce::TemplateProcessor::TestPage` - used for generating static test pages
* `HooplaSalesforce::TemplateProcessor::Generic` - used for any other files

We'll probably start packaging a large set of default helpers with the gem once we have enough projects to demonstrate which helpers should be considered core. If you have recommendations feel free to contact us.

Generating Static Test Pages
----------------------------

We can also generate static test pages from your Visual Force pages by using:

    rake hsf:testpages

This makes a `src/pages-test` folder which contains HTML versions of your VisualForce pages. We find this a useful way to do styling and client-side testing. At the moment we only support a few helpers which can generate equivalent VisualForce and HTML, but you can use the template helper technique from the previous section to make more for yourself. The currently implemented helpers are in (template_processor.rb)[http://github.com/hoopla/hoopla_salesforce/blob/master/lib/hoopla_salesforce/template_processor.rb].

Running tests
-------------

Use WEB_TEST=true to run via web ui. Default will run during deployment. Use TEST_NAMES=Test1,Test2,etc to run specific tests (or TEST_NAMES="" to skip tests).

(more documentation pending, this feature is still experimental)
