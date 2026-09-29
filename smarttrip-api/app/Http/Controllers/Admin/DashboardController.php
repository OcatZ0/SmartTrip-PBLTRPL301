<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;

/**
 * F014/F024: "needs attention" overview + sync/quota status (docs/prd
 * Section 8). Stats are stubbed until places/candidates tables exist.
 */
class DashboardController extends Controller
{
    public function index()
    {
        return view('admin.dashboard.index');
    }
}
