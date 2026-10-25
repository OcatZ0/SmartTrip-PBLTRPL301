<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class UseActorDatabaseConnection
{
    /**
     * Switches the default database connection to the PostgreSQL role of the
     * actor the request belongs to: the mobile API (and the public auth pages
     * it opens from email) runs as wisatawan, everything else as admin. The DB
     * then enforces each side's grants even if a query escapes the app's checks.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $isWisatawan = $request->is('api/*') || $request->is('auth/*');
        $connection = config('database.actor_connections.'.($isWisatawan ? 'wisatawan' : 'admin'));

        if ($connection) {
            DB::setDefaultConnection($connection);
        }

        return $next($request);
    }
}
