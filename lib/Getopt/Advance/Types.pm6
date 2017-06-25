
use Getopt::Advance::Option;
use Getopt::Advance::Exception;

my grammar Grammar::Option {
	rule TOP {
		^ <option> $
	}

	token option {
		[
			<short>? '|' <long>? '=' <type>
			|
			<name> '=' <type>
		]
        [ <optional> | <deactivate> ]?
        [ <optional> | <deactivate> ]?
	}

	token short {
		<name>
	}

	token long {
		<name>
	}

	token name {
		<-[\|\=]>+
	}

	token type {
		\w+
	}

	token optional {
		'!'
	}

	token deactivate {
		'/'
	}
}

my class Actions::Option {
	has $.opt-deactivate;
	has $.opt-optional;
	has $.opt-type;
	has $.opt-long;
	has $.opt-short;

	method option($/) {
		without ($<long> | $<short> ) {
			my $name = $<name>.Str;

			$name.chars > 1 ?? ($!opt-long = $name) !! ($!opt-short = $name);
		}
	}

	method short($/) {
		$!opt-short = $/.Str;
	}

	method long($/) {
		$!opt-long = $/.Str;
	}

	method type($/) {
		$!opt-type = $/.Str;
	}

	method optional($/) {
		$!opt-optional = True;
	}

	method deactivate($/) {
		$!opt-deactivate = True;
	}
}

class Types::Manager {
    has %.types handles <AT-KEY keys values kv pairs>;

    method has(Str $name --> Bool) {
        %!types{$name}:exists;
    }

    method innername(Str:D $name) {
        %!types{$name}.type;
    }

    method register(Str:D $name, Mu:U $type --> ::?CLASS:D) {
        if not self.has($name) {
            %!types{$name} = $type;
        }
        self;
    }

    sub opt-string-parse(Str $str) {
        my $action = Actions::Option.new;
        unless Grammar::Option.parse($str, :actions($action)) {
            raise-error("{$str}: Unable to parse option string!");
        }
        return $action;
    }

    #`( Option::Base
        has @.name;
        has &.callback;
        has $.optional;
        has $.annotation;
        has $.value;
        has $.default-value;
    )
    multi method create(Str $str, :$value, :&callback) {
        my $setting = &opt-string-parse($str);
        my $option;

        unless %!types{$setting.opt-type} ~~ Option {
            raise-error("{$setting.opt-type}: Invalid option type!");
        }
        $option = %!types{$setting.opt-type}.new(
			long 		=> $setting.opt-short // "",
            short       => $setting.opt-long // "",
            callback    => &callback,
            optional    => $setting.opt-optional,
            value       => $value,
            deactivate  => $setting.opt-deactivate,
        );
        $option;
    }

    multi method create(Str $str,  Str:D $annotation, :$value, :&callback) {
        my $setting = &opt-string-parse($str);
        my $option;

        unless %!types{$setting.opt-type} ~~ Option {
            raise-error("{$setting.opt-type}: Invalid option type!");
        }
        $option = %!types{$setting.opt-type}.new(
			long 		=> $setting.opt-short // "",
			short       => $setting.opt-long // "",
            callback    => &callback,
            optional    => $setting.opt-optional,
            value       => $value,
            annotation  => $annotation,
            deactivate  => $setting.opt-deactivate,
        );
        $option;
    }

	method clone(*%_) {
		self.bless(
			types => %_<types> // %!types.clone,
		);
		nextwith(|%_);
	}
}