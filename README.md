# EctoS3

## Testing

1) Run `docker-compose up` to bring up the external test dependencies

2) Run `MIX_ENV=test mix ecto.create` to create the test Sql database.  This is used for some of the property-based tests.

